# Protocol Improvements Plan

## Architectural rule (applies to every step)
The **coordinator** is the only validator that handles cross-UTxO logic. Sub-validators (`pair_state`, `receiver`, `payment_hook`, `reference_holder`) only check local invariants + "coordinator/admin present and names me".

---

## Step 0 — Reference script reclaim ✅ DONE

### `contracts/aiken/validators/reference_holder.ak`

Replace current always-`False` validator with admin-gated spend:

```aiken
use aiken/collection/list
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
use dia_cardano_oracle/config_logic

validator reference_holder(
  config_policy_id: PolicyId,
  config_asset_name: AssetName,
) {
  spend(
    _datum: Option<Data>,
    _redeemer: Data,
    _own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(config_input) =
      list.find(
        list.concat(self.inputs, self.reference_inputs),
        fn(input) {
          assets.quantity_of(input.output.value, config_policy_id, config_asset_name) == 1
        },
      )
    expect InlineDatum(config_data) = config_input.output.datum
    expect config_datum: config_logic.ConfigDatum = config_data
    config_logic.has_config_signer(config_datum, self)
  }

  else(_) {
    False
  }
}
```

### Off-chain

- `offchain/cli/src/init/protocol-init.ts`: pass `configPolicyId` + `configAssetName` when building `reference_holder` validator (currently parameter-less).
- CLI command `preview:reclaim-reference-script --script <name>`:
  - `--script` names match publish commands 1:1: `config` reclaims global.config + global.coordinator together (2 UTxOs, same tx as publish); `payment-hook` reclaims global.paymentHook alone; `client` reclaims client.receiver + client.pair + client.pairMint together (3 UTxOs, same tx as publish).
  - Builds a single tx spending all UTxOs for that name, with the Config UTxO as reference input + admin signature.
  - Sends ADA to admin wallet. Clears the reclaimed entries in the artifact.
- Update protocol artifact schema: `referenceHolderValidatorHash` and `referenceHolderAddress` live inside `scripts` (set by `preview:config:parameterize`).

### Tests

- Aiken: admin signer accepted, non-signer rejected, missing config rejected.
- Emulator harness: bootstrap → publish reference scripts → reclaim → verify ADA returns to admin.

---

## Step 1 — `registered_pairs` in ReceiverDatum

### `contracts/aiken/lib/dia_cardano_oracle/receiver_logic.ak`

Add field `registered_pairs: List<ByteArray>` to `ReceiverDatum`.

Add `register_pairs_transition(previous, next, new_pair_names) -> Bool`:
- `!list.any(new_pair_names, fn(n) { list.has(previous.registered_pairs, n) })`
- `next.registered_pairs == list.concat(previous.registered_pairs, new_pair_names)`
- `balance_lovelace`, `accrued_to_hook_lovelace`, `min_utxo_lovelace` unchanged.

Modify `top_up_transition`, `accrue_fee_transition`, `settle_transition`, `withdraw_transition`: add `next.registered_pairs == previous.registered_pairs`.

Add `registered_pairs: []` to `sample_receiver` and all test fixtures.

### `contracts/aiken/validators/receiver.ak`

Bootstrap initializes `registered_pairs: []` and `min_utxo_lovelace: 5_000_000`.

### `contracts/aiken/validators/update_coordinator.ak`

Add helper `valid_register_pairs(self, new_pair_names, receiver_policy_id, receiver_asset_name)`:
- If `new_pair_names == []`: return `True`.
- Find receiver input + output, decode datums, call `register_pairs_transition`.

In `valid_single_update` create path: call `valid_register_pairs(self, [witness.pair_token_name], witness.receiver_policy_id, witness.receiver_asset_name)`.

In `valid_batch_update`: extract `create_pair_names` (witnesses with `pair_input_count == 0`) before `list.all`, call `valid_register_pairs(self, create_pair_names, ...)` once.

### Off-chain

`update.ts` and `update-batch.ts`: when `isCreate`, build receiver output with `registered_pairs = receiverInput.registered_pairs ++ [pair_token_name]`.

---

## Step 2 — `UpdateMinUtxo` admin redeemer

### `contracts/aiken/lib/dia_cardano_oracle/receiver_logic.ak`

Add `update_min_utxo_transition(previous, next, new_min) -> Bool`:
- `new_min > 0`
- `next.min_utxo_lovelace == new_min`
- `balance_lovelace`, `accrued_to_hook_lovelace`, `registered_pairs` unchanged.

### `contracts/aiken/validators/receiver.ak`

Add `UpdateMinUtxo { new_min_utxo_lovelace: Int }` to `ReceiverRedeemer`.

Spend case:
```aiken
UpdateMinUtxo { new_min_utxo_lovelace } -> and {
    config_logic.has_config_signer(config_datum, self),
    receiver_logic.update_min_utxo_transition(current_datum, next_datum, new_min_utxo_lovelace),
  }
```

### `contracts/aiken/validators/pair_state.ak`

Add `UpdateMinUtxo { new_min_utxo_lovelace: Int }` to `PairSpendAction`.

Spend case checks: config signer, `new_min_utxo_lovelace > 0`, all `PairDatum` fields unchanged except `min_utxo_lovelace`.

### Payment hook

No code change. Existing `AdminUpdate` already permits `min_utxo_lovelace` change (it only freezes accrued/lifetime fields). `exact_locked_lovelace` enforces ADA adjustment.

### Off-chain

CLI command `update-min-utxo --target <receiver|pair|hook> --address <utxo> --new-min <lovelace>`.

---

## Step 3 — Efficiency (target: batch-10)

### `contracts/aiken/lib/dia_cardano_oracle/oracle_logic.ak`

Make `domain_separator` `pub`.

Add `oracle_intent_hash_with_sep(domain_sep, intent) -> ByteArray` (skips recomputing the separator).

Modify `has_valid_signature` signature: take `intent_hash: ByteArray` parameter. Remove internal hash call.

Modify `next_pair_matches_witness` and `initial_pair_matches_witness`: take `domain_sep: ByteArray` parameter. Compute `intent_hash` once via `oracle_intent_hash_with_sep`. Pass to `has_valid_signature`.

### `contracts/aiken/validators/update_coordinator.ak`

In `valid_batch_update`: compute `let domain_sep = oracle_logic.domain_separator(config_datum.domain_data)` once before `list.all`. Pass to witness verifications.

Replace `unique_pair_units` + `witnesses_share_pair_policy` with single O(N) check requiring strict ascending order:
```aiken
fn witnesses_sorted_unique_same_policy(witnesses) -> Bool {
  when witnesses is {
    [] | [_] -> True
    [a, b, ..rest] -> and {
        a.pair_policy_id == b.pair_policy_id,
        bytearray.compare(a.pair_token_name, b.pair_token_name) == Less,
        witnesses_sorted_unique_same_policy([b, ..rest]),
      }
  }
}
```

Replace `count_pair_token_inputs` + `find_pair_input` with `find_unique_pair_input(inputs, policy, name) -> Option<Input>` (single pass; `None` if 0 or >1).

Replace `count_pair_token_outputs` + `find_pair_output` with `find_unique_pair_output` (same pattern).

Delete the four old helpers.

### Off-chain `offchain/cli/src/transactions/update-batch.ts`

Sort witnesses by `pair_token_name` (lexicographic ascending bytes) before building `ApplyBatch` redeemer.

---

## Tests required

| Step | Test |
|------|------|
| 0 | reference_holder accepts admin, rejects non-admin, rejects missing config |
| 0 | emulator: bootstrap → publish → reclaim → ADA returned |
| 1 | coordinator rejects creating already-registered pair |
| 1 | coordinator accepts new pair and updates receiver list |
| 2 | UpdateMinUtxo on receiver: admin accepted, non-admin rejected |
| 2 | UpdateMinUtxo on pair_state: admin accepted, non-admin rejected |
| 3 | witnesses_sorted_unique_same_policy rejects bad order, mixed policies, duplicates |
| 3 | batch-10 fits within ExBudget |

---

## Implementation order

0. Step 0 (reclaim) — required before mainnet, low risk.
1. Step 3 (efficiency) — no interface changes.
2. Step 1 (registered_pairs) — datum + coordinator + off-chain together.
3. Step 2 (UpdateMinUtxo) — independent of 1.
