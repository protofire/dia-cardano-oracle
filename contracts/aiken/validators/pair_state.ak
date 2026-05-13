use aiken/collection/dict
use aiken/collection/list
use aiken/crypto.{ScriptHash}
use cardano/address.{Script}
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction,
}
use dia_cardano_oracle/config_logic
use dia_cardano_oracle/coordinator_logic.{
  coordinator_in_update_mode, pair_mint_intent_satisfied,
}
use dia_cardano_oracle/oracle_logic

pub type PairMintAction {
  MintPairs
}

pub type PairSpendAction {
  /// Spent during an oracle update (single or batch). The script body
  /// is intentionally minimal: NFT continuity, exact ADA locking, and
  /// cross-script redeemer-confusion defence via
  /// `coordinator_in_update_mode`. Datum semantics, signature recovery,
  /// freshness, intent expiry, receiver presence, and one-input-per-
  /// witness accounting are all enforced once by `update_coordinator`
  /// — duplicating them here would multiply that cost by N pair scripts
  /// inside a batch.
  ApplyUpdate
  /// Admin-only update of min_utxo_lovelace. Requires config signer authorization.
  UpdateMinUtxo { new_min_utxo_lovelace: Int }
}

validator pair_state(
  config_policy_id: PolicyId,
  config_asset_name: AssetName,
  // `receiver_hash` ties this `pair_state` instance to one client's
  // receiver script. The body no longer references it directly —
  // `update_coordinator` enforces receiver identity for every batch
  // witness, and the Pair NFT mint policy is itself parameterised by
  // `receiver_hash`, so the binding survives at the script-hash level.
  // The leading `_` silences Aiken's unused-binding warning; the
  // parameter slot is still applied to the compiled validator, so
  // each client still gets its own `pair_state` script address.
  _receiver_hash: ScriptHash,
) {
  mint(action: PairMintAction, policy_id: PolicyId, self: Transaction) {
    let MintPairs = action
    let minted_pairs =
      self.mint
        |> assets.tokens(policy_id)
        |> dict.to_pairs()

    expect Some(config_input) =
      list.find(
        self.reference_inputs,
        fn(input) {
          assets.quantity_of(
            input.output.value,
            config_policy_id,
            config_asset_name,
          ) == 1
        },
      )

    expect InlineDatum(config_datum_data) = config_input.output.datum
    expect config_datum: config_logic.ConfigDatum = config_datum_data

    and {
      list.length(minted_pairs) > 0,
      list.all(
        minted_pairs,
        fn(minted_pair) {
          let Pair(asset_name, quantity) = minted_pair
          and {
            quantity == 1,
            has_pair_output(self.outputs, policy_id, asset_name),
            // Binds the coordinator redeemer to this exact Pair NFT AND
            // re-asserts intent expiry locally (defence-in-depth: every
            // path that consumes a signed intent enforces expiry, not
            // only the coordinator's own redeemer body).
            pair_mint_intent_satisfied(
              self,
              config_datum,
              policy_id,
              asset_name,
            ),
          }
        },
      ),
      config_logic.valid_config_state(config_datum),
    }
  }

  spend(
    maybe_datum: Option<oracle_logic.PairDatum>,
    redeemer: PairSpendAction,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(current_datum) = maybe_datum
    expect Some(own_input) =
      list.find(self.inputs, fn(input) { input.output_reference == own_ref })
    expect Script(own_policy_id) = own_input.output.address.payment_credential

    expect [Pair(pair_token_name, 1)] =
      own_input.output.value
        |> assets.tokens(own_policy_id)
        |> dict.to_pairs()

    when redeemer is {
      ApplyUpdate -> {
        // Find the continuation pair output by NFT name. We only need
        // the output's address + lovelace; the datum is decoded once,
        // by `update_coordinator`, so we do not deserialize it here.
        expect Some(pair_output) =
          list.find(
            self.outputs,
            fn(output) {
              assets.quantity_of(output.value, own_policy_id, pair_token_name) == 1
            },
          )

        // Read the Config UTxO (reference input) ONLY to learn the
        // coordinator credential. We do not call
        // `valid_config_state` here — the coordinator's own
        // execution does, and that runs in the same tx.
        expect Some(config_input) =
          list.find(
            self.reference_inputs,
            fn(input) {
              assets.quantity_of(
                input.output.value,
                config_policy_id,
                config_asset_name,
              ) == 1
            },
          )
        expect InlineDatum(config_datum_data) = config_input.output.datum
        expect config_datum: config_logic.ConfigDatum = config_datum_data

        and {
          // NFT continuity: the same Pair NFT lives at the same per-
          // client script address in the continuation output.
          pair_output.address.payment_credential == Script(own_policy_id),
          // Exact ADA locking. The coordinator's
          // `next_pair_matches_witness` enforces
          // `previous.min_utxo_lovelace == next.min_utxo_lovelace` for
          // updates, so checking against `current_datum.min_utxo_lovelace`
          // covers both input and output without decoding `next_datum`
          // again here.
          assets.lovelace_of(own_input.output.value) == current_datum.min_utxo_lovelace,
          assets.lovelace_of(pair_output.value) == current_datum.min_utxo_lovelace,
          // Cross-script redeemer-confusion defence: the coordinator
          // MUST be running in `ApplySingle` or `ApplyBatch` mode
          // (not `ApplySettle`). `coordinator_in_update_mode` uses a
          // `CoordinatorRedeemerFingerprint` that decodes only the
          // outer constructor tag, so this stays cheap even when the
          // coordinator's witness list is large. Every other safety
          // property of an update — datum semantics, signature
          // recovery, intent freshness/expiry, receiver presence,
          // canonical witness ordering, one-pair-input-per-witness
          // accounting — is enforced once by `update_coordinator`
          // inside the same tx; duplicating any of it here would
          // multiply the cost by N pair scripts in a batch.
          coordinator_in_update_mode(self, config_datum),
        }
      }

      UpdateMinUtxo { new_min_utxo_lovelace } -> {
        // Admin-gated: full decoding of next_datum + config is
        // worthwhile here because this branch is rare and singular,
        // not part of any high-throughput batch.
        expect Some(pair_output) =
          list.find(
            self.outputs,
            fn(output) {
              assets.quantity_of(output.value, own_policy_id, pair_token_name) == 1
            },
          )
        expect InlineDatum(output_datum) = pair_output.datum
        expect next_datum: oracle_logic.PairDatum = output_datum
        expect Some(config_input) =
          list.find(
            self.reference_inputs,
            fn(input) {
              assets.quantity_of(
                input.output.value,
                config_policy_id,
                config_asset_name,
              ) == 1
            },
          )
        expect InlineDatum(config_datum_data) = config_input.output.datum
        expect config_datum: config_logic.ConfigDatum = config_datum_data

        and {
          config_logic.has_config_signer(config_datum, self),
          new_min_utxo_lovelace > 0,
          next_datum.min_utxo_lovelace == new_min_utxo_lovelace,
          next_datum.pair_id == current_datum.pair_id,
          next_datum.price == current_datum.price,
          next_datum.timestamp == current_datum.timestamp,
          next_datum.nonce == current_datum.nonce,
          next_datum.intent_hash == current_datum.intent_hash,
          next_datum.signer == current_datum.signer,
          oracle_logic.valid_pair_state(current_datum),
          oracle_logic.valid_pair_state(next_datum),
          assets.quantity_of(pair_output.value, own_policy_id, pair_token_name) == 1,
          pair_output.address.payment_credential == Script(own_policy_id),
          pair_token_name == oracle_logic.pair_asset_name(current_datum.pair_id),
          config_logic.valid_config_state(config_datum),
          oracle_logic.exact_locked_lovelace(own_input.output, current_datum),
          oracle_logic.exact_locked_lovelace(pair_output, next_datum),
        }
      }
    }
  }

  else(_) {
    False
  }
}

fn has_pair_output(
  outputs: List<Output>,
  pair_policy_id: PolicyId,
  pair_asset_name: ByteArray,
) -> Bool {
  when
    list.find(
      outputs,
      fn(output) {
        assets.quantity_of(output.value, pair_policy_id, pair_asset_name) == 1
      },
    )
  is {
    Some(matching_output) ->
      when matching_output.datum is {
        InlineDatum(output_datum) -> {
          expect pair_datum: oracle_logic.PairDatum = output_datum
          and {
            matching_output.address.payment_credential == Script(pair_policy_id),
            oracle_logic.pair_asset_name(pair_datum.pair_id) == pair_asset_name,
            oracle_logic.valid_pair_state(pair_datum),
            oracle_logic.exact_locked_lovelace(matching_output, pair_datum),
          }
        }

        _ -> False
      }

    None -> False
  }
}

