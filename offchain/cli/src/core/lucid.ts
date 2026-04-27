import { Lucid } from "@lucid-evolution/lucid";
import { Blockfrost, Koios } from "@lucid-evolution/provider";

import { getCliConfig } from "./config.js";

type ProtocolParameters = Awaited<
  ReturnType<Blockfrost["getProtocolParameters"]>
>;

type BlockfrostProtocolParametersResponse = {
  min_fee_a: string | number;
  min_fee_b: string | number;
  max_tx_size: string | number;
  max_val_size: string | number;
  key_deposit: string | number;
  pool_deposit: string | number;
  drep_deposit: string | number;
  gov_action_deposit: string | number;
  price_mem: string | number;
  price_step: string | number;
  max_tx_ex_mem: string | number;
  max_tx_ex_steps: string | number;
  coins_per_utxo_size: string | number;
  collateral_percent: string | number;
  max_collateral_inputs: string | number;
  min_fee_ref_script_cost_per_byte: string | number;
  cost_models_raw: {
    PlutusV1: number[];
    PlutusV2: number[];
    PlutusV3: number[];
  };
};

export async function makeConfiguredProvider(): Promise<Blockfrost | Koios> {
  const config = getCliConfig();

  if (config.cardanoProvider === "Koios") {
    return new Koios(config.koiosApiUrl);
  }

  const provider = new Blockfrost(
    config.blockfrostApiUrl,
    config.blockfrostProjectId,
  );
  provider.getProtocolParameters = async (): Promise<ProtocolParameters> =>
    fetchBlockfrostProtocolParameters(
      config.blockfrostApiUrl,
      config.blockfrostProjectId,
    );

  return provider;
}

export async function makeConfiguredLucid(): Promise<
  Awaited<ReturnType<typeof Lucid>>
> {
  const config = getCliConfig();
  const provider = await makeConfiguredProvider();

  return Lucid(provider, config.cardanoNetwork);
}

export async function selectConfiguredWallet(
  lucid: Awaited<ReturnType<typeof Lucid>>,
): Promise<"seed" | "private-key"> {
  const seed = process.env.CARDANO_WALLET_SEED?.trim();
  const privateKey = process.env.CARDANO_PRIVATE_KEY?.trim();

  if (seed) {
    lucid.selectWallet.fromSeed(seed);
    return "seed";
  }

  if (privateKey) {
    lucid.selectWallet.fromPrivateKey(privateKey);
    return "private-key";
  }

  throw new Error(
    "Missing wallet configuration. Set CARDANO_WALLET_SEED or CARDANO_PRIVATE_KEY.",
  );
}

async function fetchBlockfrostProtocolParameters(
  blockfrostApiUrl: string,
  blockfrostProjectId: string,
): Promise<ProtocolParameters> {
  const response = await fetch(`${blockfrostApiUrl}/epochs/latest/parameters`, {
    headers: {
      project_id: blockfrostProjectId,
    },
    signal: AbortSignal.timeout(20_000),
  });

  if (!response.ok) {
    throw new Error(
      `Unable to fetch protocol parameters from Blockfrost (${response.status} ${response.statusText}).`,
    );
  }

  const latest = (await response.json()) as BlockfrostProtocolParametersResponse;

  return {
    minFeeA: Number(latest.min_fee_a),
    minFeeB: Number(latest.min_fee_b),
    maxTxSize: Number(latest.max_tx_size),
    maxValSize: Number(latest.max_val_size),
    keyDeposit: BigInt(latest.key_deposit),
    poolDeposit: BigInt(latest.pool_deposit),
    drepDeposit: BigInt(latest.drep_deposit),
    govActionDeposit: BigInt(latest.gov_action_deposit),
    priceMem: Number(latest.price_mem),
    priceStep: Number(latest.price_step),
    maxTxExMem: BigInt(latest.max_tx_ex_mem),
    maxTxExSteps: BigInt(latest.max_tx_ex_steps),
    coinsPerUtxoByte: BigInt(latest.coins_per_utxo_size),
    collateralPercentage: Number(latest.collateral_percent),
    maxCollateralInputs: Number(latest.max_collateral_inputs),
    minFeeRefScriptCostPerByte: Number(latest.min_fee_ref_script_cost_per_byte),
    costModels: {
      PlutusV1: indexedCostModel(latest.cost_models_raw.PlutusV1),
      PlutusV2: indexedCostModel(latest.cost_models_raw.PlutusV2),
      PlutusV3: indexedCostModel(latest.cost_models_raw.PlutusV3),
    },
  };
}

function indexedCostModel(values: number[]): Record<string, number> {
  return Object.fromEntries(
    values.map((value, index) => [index.toString(), value]),
  );
}
