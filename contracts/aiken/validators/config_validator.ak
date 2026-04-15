use aiken/collection/list
use cardano/assets
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
use dia_cardano_oracle/config_logic

validator config_validator(
  config_policy_id: PolicyId,
  config_asset_name: AssetName,
) {
  spend(
    maybe_datum: Option<config_logic.ConfigDatum>,
    redeemer: config_logic.ConfigRedeemer,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(current_datum) = maybe_datum
    let Transaction { inputs, outputs, .. } = self

    expect Some(own_input) =
      list.find(inputs, fn(input) { input.output_reference == own_ref })

    expect Some(config_output) =
      list.find(
        outputs,
        fn(output) {
          assets.quantity_of(output.value, config_policy_id, config_asset_name) == 1
        },
      )

    expect InlineDatum(output_datum) = config_output.datum
    expect next_datum: config_logic.ConfigDatum = output_datum

    and {
      assets.quantity_of(own_input.output.value, config_policy_id, config_asset_name) == 1,
      assets.quantity_of(config_output.value, config_policy_id, config_asset_name) == 1,
      config_logic.valid_config_state(current_datum),
      config_logic.valid_config_state(next_datum),
      config_logic.has_config_signer(current_datum, self),
      when redeemer is {
        config_logic.UpdateConfig ->
          config_logic.same_allowed_pairs(current_datum, next_datum)

        config_logic.RegisterPair(pair) ->
          config_logic.registered_pair_transition(current_datum, next_datum, pair)
      },
    }
  }

  else(_) {
    False
  }
}
