use aiken/collection/dict
use aiken/collection/list
use cardano/assets
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
use dia_cardano_oracle/config_logic
use dia_cardano_oracle/oracle_logic

validator oracle_receiver(
  config_policy_id: PolicyId,
  config_asset_name: AssetName,
  pair_policy_id: PolicyId,
) {
  spend(
    maybe_datum: Option<oracle_logic.OracleDatum>,
    redeemer: oracle_logic.OracleRedeemer,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(current_datum) = maybe_datum
    let Transaction {
      inputs,
      reference_inputs,
      outputs,
      ..
    } = self

    expect Some(own_input) =
      list.find(inputs, fn(input) { input.output_reference == own_ref })

    expect [Pair(pair_token_name, 1)] =
      own_input.output.value
        |> assets.tokens(pair_policy_id)
        |> dict.to_pairs()

    expect Some(config_input) =
      list.find(
        reference_inputs,
        fn(input) {
          assets.quantity_of(input.output.value, config_policy_id, config_asset_name) == 1
        },
      )

    expect InlineDatum(config_datum_data) = config_input.output.datum
    expect config_datum: config_logic.ConfigDatum = config_datum_data

    expect Some(pair_output) =
      list.find(
        outputs,
        fn(output) {
          assets.quantity_of(output.value, pair_policy_id, pair_token_name) == 1
        },
      )

    expect InlineDatum(output_datum) = pair_output.datum
    expect next_datum: oracle_logic.OracleDatum = output_datum

    and {
      oracle_logic.valid_oracle_state(current_datum),
      oracle_logic.valid_oracle_state(next_datum),
      assets.quantity_of(pair_output.value, pair_policy_id, pair_token_name) == 1,
      oracle_logic.valid_oracle_update(
        current_datum,
        config_datum,
        pair_token_name,
        redeemer,
        next_datum,
      ),
      oracle_logic.fees_paid(config_datum, outputs),
    }
  }

  else(_) {
    False
  }
}
