use aiken/collection/dict
use aiken/collection/list
use cardano/assets
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{InlineDatum, Output, OutputReference, Transaction}
use dia_cardano_oracle/config_logic

pub type ConfigNftAction {
  MintConfig
}

validator config_nft(
  bootstrap_ref: OutputReference,
  expected_asset_name: AssetName,
) {
  mint(action: ConfigNftAction, policy_id: PolicyId, self: Transaction) {
    let MintConfig = action

    expect [Pair(asset_name, quantity)] =
      self.mint
        |> assets.tokens(policy_id)
        |> dict.to_pairs()

    let consumes_bootstrap_input =
      list.any(self.inputs, fn(input) { input.output_reference == bootstrap_ref })

    and {
      consumes_bootstrap_input,
      asset_name == expected_asset_name,
      quantity == 1,
      has_config_bootstrap_output(
        self.outputs,
        policy_id,
        expected_asset_name,
      ),
    }
  }

  else(_) {
    False
  }
}

fn has_config_bootstrap_output(
  outputs: List<Output>,
  config_policy_id: PolicyId,
  config_asset_name: AssetName,
) -> Bool {
  outputs
    |> list.find(
        fn(output) {
          assets.quantity_of(output.value, config_policy_id, config_asset_name) == 1
        },
      )
    |> has_valid_config_datum
}

fn has_valid_config_datum(output: Option<Output>) -> Bool {
  when output is {
    Some(config_output) ->
      when config_output.datum is {
        InlineDatum(output_datum) -> {
          expect config_datum: config_logic.ConfigDatum = output_datum
          config_logic.valid_config_state(config_datum)
        }

        _ -> False
      }

    None -> False
  }
}
