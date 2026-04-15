use aiken/collection/dict
use aiken/collection/list
use cardano/assets
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{InlineDatum, Output, Transaction}
use dia_cardano_oracle/config_logic
use dia_cardano_oracle/oracle_logic

pub type PairNftAction {
  CreatePair
}

validator pair_nft(
  config_policy_id: PolicyId,
  config_asset_name: AssetName,
) {
  mint(action: PairNftAction, policy_id: PolicyId, self: Transaction) {
    let CreatePair = action

    expect [Pair(asset_name, quantity)] =
      self.mint
        |> assets.tokens(policy_id)
        |> dict.to_pairs()

    expect Some(config_input) =
      list.find(
        self.inputs,
        fn(input) {
          assets.quantity_of(input.output.value, config_policy_id, config_asset_name) == 1
        },
      )

    expect Some(config_output) =
      list.find(
        self.outputs,
        fn(output) {
          assets.quantity_of(output.value, config_policy_id, config_asset_name) == 1
        },
      )

    expect InlineDatum(config_input_datum) = config_input.output.datum
    expect previous_datum: config_logic.ConfigDatum = config_input_datum

    expect InlineDatum(config_output_datum) = config_output.datum
    expect next_datum: config_logic.ConfigDatum = config_output_datum

    expect Some(pair) = config_logic.find_pair_by_token_name(next_datum, asset_name)

    and {
      quantity == 1,
      config_logic.registered_pair_transition(previous_datum, next_datum, pair),
      has_oracle_bootstrap_output(self.outputs, policy_id, next_datum, pair),
    }
  }

  else(_) {
    False
  }
}

fn has_oracle_bootstrap_output(
  outputs: List<Output>,
  pair_policy_id: PolicyId,
  config_datum: config_logic.ConfigDatum,
  pair: config_logic.PairEntry,
) -> Bool {
  outputs
    |> list.find(
        fn(output) {
          assets.quantity_of(output.value, pair_policy_id, pair.token_name) == 1
        },
      )
    |> has_valid_initial_oracle_datum(config_datum, pair)
}

fn has_valid_initial_oracle_datum(
  output: Option<Output>,
  config_datum: config_logic.ConfigDatum,
  pair: config_logic.PairEntry,
) -> Bool {
  when output is {
    Some(matching_output) ->
      when matching_output.datum is {
        InlineDatum(output_datum) -> {
          expect oracle_datum: oracle_logic.OracleDatum = output_datum
          oracle_logic.valid_initial_oracle_datum(pair, config_datum, oracle_datum)
        }

        _ -> False
      }

    None -> False
  }
}
