# Milestone 1 Preview Evidence

Source of truth: [`final-cardano-milestones.md`](../../final-cardano-milestones.md).

Scope: Milestone 1 validation on Cardano Preview. Cardano mainnet deployment and final mainnet evidence are not included here.

Verification date: **20260508-0** (chain walk + local tooling, current bytecode).

Network: Cardano Preview.

Evidence pack location: [`docs/milestones/evidence/m1-preview-20260508-083625/`](./) — captured logs for every CLI step plus `SUMMARY.json` with the final on-chain state.

## Official Milestone 1 Outputs

| Official output | Repository status |
| --- | --- |
| Aiken oracle smart contract ported to Cardano UTxO model | Complete |
| Compiled contract | Complete: `contracts/aiken/plutus.json` |
| Unit/integration test coverage | `aiken check` — unit tests passed; `offchain/cli` `npm run test` + typecheck + build green. End-to-end Preview chain walk captured below. |
| Deployment scripts | Complete: `offchain/cli` runbook and CLI commands |
| Documentation for Cardano developers | Complete in repository: root README, Aiken README, CLI runbook, architecture document |
| Verified Cardano mainnet deployment and execution hashes | Pending (mainnet not executed yet — separate gate) |

## Preview transactions executed end-to-end

All transactions below were submitted on Cardano Preview and confirmed. The chain walk demonstrates every Milestone 1 protocol surface including **Settle**, **reclaim**, and **republish** of a reference-script UTxO.

The integration exercises **eleven price pairs** (`USDC/USD`, `BTC/USD`, `ETH/USD`, `ADA/USD`, `USDT/USD`, `DAI/USD`, `SOL/USD`, `BNB/USD`, `XRP/USD`, `MATIC/USD`, `DOT/USD`). All eleven are bootstrapped via individual `preview:update` transactions. A subsequent batch transaction updates the first 6 non-USDC pairs in one `preview:update:batch` call.

### Protocol bootstrap (one-time)

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 1 | `preview:protocol:init` | *(local artifact)* | — | [`01-protocol-init.log`](./01-protocol-init.log) |
| 2 | `preview:config:parameterize` | *(local artifact)* | — | [`02-config-parameterize.log`](./02-config-parameterize.log) |
| 3 | `preview:config:bootstrap` | `7c38e74527bb3b9ad66356f91c7fa9530c9043a7328ba9dd180f6313d48e15a9` | 0.300362 ADA | [`03-config-bootstrap.log`](./03-config-bootstrap.log) |
| 4 | `preview:config:reference-scripts` (Config+Coordinator) | `1df7b92cd7bd74883ec27dcd5705219f7f2c5e695ee488879bdd15c323e80fbe` | 0.610693 ADA | [`04-config-reference-scripts.log`](./04-config-reference-scripts.log) |
| 5 | `preview:payment-hook:parameterize` | *(local artifact)* | — | [`05-payment-hook-parameterize.log`](./05-payment-hook-parameterize.log) |
| 6 | `preview:payment-hook:bootstrap` | `0585599bec05f50104ed5fe1c0ef76e858f560352a94ba2c67f18fac4670a739` | 0.598308 ADA | [`06-payment-hook-bootstrap.log`](./06-payment-hook-bootstrap.log) |
| 7 | `preview:payment-hook:reference-script` | `6bc182e085531aab0aec1b487d8756d1d4f10807e0b0f0bdc292ea8b0f6ff3c5` | 0.387261 ADA | [`07-payment-hook-reference-script.log`](./07-payment-hook-reference-script.log) |

### Client onboarding (`client-a`)

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 8 | `preview:client:init` | *(local artifact)* | — | [`08-client-init.log`](./08-client-init.log) |
| 9 | `preview:receiver:parameterize` | *(local artifact)* | — | [`09-receiver-parameterize.log`](./09-receiver-parameterize.log) |
| 10 | `preview:receiver:bootstrap` | `1cdfe637c8a242e9f381de1582fabeb53075c66ff8044c2e3a5909080ca123e4` | 0.425212 ADA | [`10-receiver-bootstrap.log`](./10-receiver-bootstrap.log) |
| 11 | `preview:reference-scripts:publish-client` (Receiver+Pair+PairMint) | `3e813d0e6b0b9f0b6990e36c0754c78b21a2557fe9d1b0214829b02fde26c60d` | 0.720561 ADA | [`11-client-reference-scripts.log`](./11-client-reference-scripts.log) |
| 12 | `preview:receiver:top-up` (top-up 1) | `c2be83d3cf68e94988820a89965a3039bf1ac5ce2d5a380e7c6c1c359fb8d344` | 0.349581 ADA | [`12-receiver-top-up.log`](./12-receiver-top-up.log) |

### Single-pair pair-create updates — 11 pairs via `preview:update`

| Step | Pair | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 13 | USDC/USD | `e117bb14e065387b1fc87b0ede4160679a201588c26c15807846897574c2a391` | 0.751794 ADA | [`13-update-usdc-bootstrap.log`](./13-update-usdc-bootstrap.log) |
| 14 | BTC/USD | `387bbb9145aa251c34892d840caa0fc46e845c8dd25953a4f7d7b53e1f3edf50` | 0.752058 ADA | [`14-bootstrap-btc-usd.log`](./14-bootstrap-btc-usd.log) |
| 15 | ETH/USD | `d4d802c788fc573bc42c7d21e585d681a15a3fefe1149366c36c18934f46b93e` | 0.752058 ADA | [`15-bootstrap-eth-usd.log`](./15-bootstrap-eth-usd.log) |
| 16 | ADA/USD | `30fdc29bb1f62b29c7cd7ea62076f37e721340531cafd37d50c5832d4a8228a9` | 0.751706 ADA | [`16-bootstrap-ada-usd.log`](./16-bootstrap-ada-usd.log) |
| 17 | USDT/USD | `9a393688677bc874ae74f92ff6f573d51826a26b620ae8e270066f12adec1b41` | 0.751794 ADA | [`17-bootstrap-usdt-usd.log`](./17-bootstrap-usdt-usd.log) |
| 18 | DAI/USD | `a2cdb62cdbab661c0365b8c6850484b88e3a6e94043baeab4aeef481425e0791` | 0.751706 ADA | [`18-bootstrap-dai-usd.log`](./18-bootstrap-dai-usd.log) |
| 19 | SOL/USD | `c72e31fdc603d78cf65de9c5fc65c649a8abd69c4f5894c650c67ce86868c73a` | 0.752058 ADA | [`19-bootstrap-sol-usd.log`](./19-bootstrap-sol-usd.log) |
| 20 | BNB/USD | `96669232921347b3aa512b778a634e6e9851de0523a17d018428d1dee1a5abc4` | 0.752058 ADA | [`20-bootstrap-bnb-usd.log`](./20-bootstrap-bnb-usd.log) |
| 21 | XRP/USD | `b4512d725ccc74f1446162df614b08289cbaadf3c512c9f99099aa9d1bb94c81` | 0.751706 ADA | [`21-bootstrap-xrp-usd.log`](./21-bootstrap-xrp-usd.log) |
| 22 | MATIC/USD | `86279ebfd095f9940c914f749026a750769cdc66a9fb4ace714b4ece8df5a9c5` | 0.751892 ADA | [`22-bootstrap-matic-usd.log`](./22-bootstrap-matic-usd.log) |
| 23 | DOT/USD | `d17e76075b24e6c7e2fdb77e7cc512fb54600532f2e3d5200c5f6730912fa934` | 0.751706 ADA | [`23-bootstrap-dot-usd.log`](./23-bootstrap-dot-usd.log) |

### Second top-up (replenish before batch)

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 24 | `preview:receiver:top-up` (top-up 2) | `b5c12f66400f34c134383ee846380e8ee733b81ec9649f0c13b0883a5f7267cf` | 0.349757 ADA | [`24-receiver-top-up-2.log`](./24-receiver-top-up-2.log) |

### Batch update — coordinator `ApplyBatch`

Batch sizes 10, 9, 8, 7 were attempted first but exceeded the per-tx Plutus ExUnits budget (each secp256k1 ECDSA verification costs ~440M CPU steps; beyond 6 verifications the batch surpasses the ~10B per-tx ceiling). Batch size **6** succeeded.

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| `preview:update:batch` (10 pairs, attempted) | *(ExUnits over budget — not submitted)* | 0 ADA | [`25-update-batch-10.log`](./25-update-batch-10.log) |
| `preview:update:batch` (9 pairs, attempted) | *(ExUnits over budget — not submitted)* | 0 ADA | [`25-update-batch-9.log`](./25-update-batch-9.log) |
| `preview:update:batch` (8 pairs, attempted) | *(ExUnits over budget — not submitted)* | 0 ADA | [`25-update-batch-8.log`](./25-update-batch-8.log) |
| `preview:update:batch` (7 pairs, attempted) | *(ExUnits over budget — not submitted)* | 0 ADA | [`25-update-batch-7.log`](./25-update-batch-7.log) |
| 25 | `preview:update:batch` (6 pairs) | `f990e95452caceb32a178d12d43a839f88c54002d4a34dec61989a2d9807a27f` | 2.230591 ADA | [`25-update-batch-6.log`](./25-update-batch-6.log) |

### Settle, withdrawals, reclaim + republish reference script

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 26 | `preview:settle` | `f4f667c03a11479fc341b87622a26c73cdf2dbeee09fca7ee49514988468faaa` | 0.753292 ADA | [`26-settle.log`](./26-settle.log) |
| 27 | `preview:receiver:withdraw` | `3eb7f58769b5412c443d30f40edefa21f90298b347dcb89dceec2959bf789aae` | 0.379981 ADA | [`27-receiver-withdraw.log`](./27-receiver-withdraw.log) |
| 28 | `preview:payment-hook:withdraw` | `c9aa09065af0d8fdd300bb7f09cc43cb659a0dd948e49c44b3f4fa2e001e2468` | 0.378096 ADA | [`28-payment-hook-withdraw.log`](./28-payment-hook-withdraw.log) |
| 29 | `preview:reclaim-reference-script --script payment-hook` | `87df862633d85710df36b80f62277a2624467dddd19a540e2625046852995d35` | 0.311558 ADA | [`29-reclaim-payment-hook-reference-script.log`](./29-reclaim-payment-hook-reference-script.log) |
| 30 | `preview:payment-hook:reference-script` (republish) | `d2d5334e13778d59fb5a373a8f22327641bbed68afc7c7544ca06f31747a8150` | 0.387261 ADA | [`30-republish-payment-hook-reference-script.log`](./30-republish-payment-hook-reference-script.log) |

## ADA flow summary

Single wallet used for all operations (DIA admin = updater = funder).

| Item | Value |
| --- | --- |
| Wallet address | `addr_test1qpgpsm75w7l9u6au7shqzsaulrtxz2gp6xw9zhun70es6tt4t3wsjavx26kmh586erf8xxhqc2y7urq5az32sjv56nyqquxj3j` |
| Initial wallet balance | **5064.387246 ADA** (5,064,387,246 lovelace) |
| Final wallet balance | **4807.133756 ADA** (4,807,133,756 lovelace) |
| Total on-chain fees paid | **16.453050 ADA** (16,453,050 lovelace) |
| Net ADA locked in protocol | **240.800440 ADA** (initial − final − fees) |

### ADA locked breakdown

| Location | ADA locked |
| --- | --- |
| Config UTxO (min-UTxO) | 5.000000 ADA |
| PaymentHook UTxO (min-UTxO + accrued) | 29.000000 ADA |
| Receiver UTxO (min-UTxO + balance + accrued) | 26.000000 ADA |
| Pair UTxOs × 11 (min-UTxO each) | 55.000000 ADA |
| Reference-script UTxOs × 6 (config+coordinator+hook+receiver+pair+pairMint) | 123.800440 ADA |
| **Total locked in protocol** | **238.800440 ADA** |

Reference-script min-UTxO breakdown: `configValidator`=10.667250 ADA, `coordinatorValidator`=34.307600 ADA, `paymentHookValidator`=22.399070 ADA, `receiverValidator`=22.205120 ADA, `pairValidator`=17.110700 ADA, `pairMintPolicy`=17.110700 ADA.

## On-chain fee audit

| Step | Operation | Tx hash (first 16 chars) | Fee paid |
| --- | --- | --- | --- |
| `preview:config:bootstrap` | `7c38e74527bb3b9a…` | 0.300362 ADA |
| `preview:config:reference-scripts` (Config+Coordinator) | `1df7b92cd7bd7488…` | 0.610693 ADA |
| `preview:payment-hook:bootstrap` | `0585599bec05f501…` | 0.598308 ADA |
| `preview:payment-hook:reference-script` | `6bc182e085531aab…` | 0.387261 ADA |
| `preview:receiver:bootstrap` | `1cdfe637c8a242e9…` | 0.425212 ADA |
| `preview:reference-scripts:publish-client` (Receiver+Pair+PairMint) | `3e813d0e6b0b9f0b…` | 0.720561 ADA |
| `preview:receiver:top-up` (top-up 1) | `c2be83d3cf68e949…` | 0.349581 ADA |
| `preview:update` — USDC/USD create | `e117bb14e065387b…` | 0.751794 ADA |
| `preview:update` — BTC/USD create | `387bbb9145aa251c…` | 0.752058 ADA |
| `preview:update` — ETH/USD create | `d4d802c788fc573b…` | 0.752058 ADA |
| `preview:update` — ADA/USD create | `30fdc29bb1f62b29…` | 0.751706 ADA |
| `preview:update` — USDT/USD create | `9a393688677bc874…` | 0.751794 ADA |
| `preview:update` — DAI/USD create | `a2cdb62cdbab661c…` | 0.751706 ADA |
| `preview:update` — SOL/USD create | `c72e31fdc603d78c…` | 0.752058 ADA |
| `preview:update` — BNB/USD create | `96669232921347b3…` | 0.752058 ADA |
| `preview:update` — XRP/USD create | `b4512d725ccc74f1…` | 0.751706 ADA |
| `preview:update` — MATIC/USD create | `86279ebfd095f994…` | 0.751892 ADA |
| `preview:update` — DOT/USD create | `d17e76075b24e6c7…` | 0.751706 ADA |
| `preview:receiver:top-up` (top-up 2) | `b5c12f66400f34c1…` | 0.349757 ADA |
| `preview:update:batch` (6 pairs) | `f990e95452caceb3…` | 2.230591 ADA |
| `preview:settle` | `f4f667c03a11479f…` | 0.753292 ADA |
| `preview:receiver:withdraw` | `3eb7f58769b5412c…` | 0.379981 ADA |
| `preview:payment-hook:withdraw` | `c9aa09065af0d8fd…` | 0.378096 ADA |
| `preview:reclaim-reference-script --script payment-hook` | `87df862633d85710…` | 0.311558 ADA |
| `preview:payment-hook:reference-script` (republish) | `d2d5334e13778d59…` | 0.387261 ADA |

**Total confirmed on-chain fees: 16.453050 ADA** (16,453,050 lovelace).

## Final on-chain state

Snapshot from [`SUMMARY.json`](./SUMMARY.json) at the end of the Preview chain walk.

### Script identities (current bytecode)

| Item | Value |
| --- | --- |
| Reference-holder address | `addr_test1wr6p5ark2rywar7q3uk0h3hv0fkwxr30yetzjm20qjmxzrsz8k8eq` |
| Config policy ID / validator hash | `2bc8084ed42b1fe62c5f29e49143a14cc3460d4c85a42042d32edc27` |
| Config NFT unit | `2bc8084ed42b1fe62c5f29e49143a14cc3460d4c85a42042d32edc274449415f434f4e464947` |
| Coordinator stake validator hash | `244082bf0c9bfd609a27649489cfcd219b0e8b0ee3fe18d908e39ff0` |
| PaymentHook policy ID / validator hash | `946b8ccbac5cf641d573f424d8737c6bd6e0f8cdeaa1cc8d62bf074b` |
| PaymentHook NFT unit | `946b8ccbac5cf641d573f424d8737c6bd6e0f8cdeaa1cc8d62bf074b4449415f5041594d454e545f484f4f4b` |
| Receiver validator hash (`client-a`) | `3a5a5405194ceee1015de51b669ea58febfd6a0204228a1cede6841f` |
| Receiver validator address (`client-a`) | `addr_test1wqa954q9r9xwacgpthj3ke575k87hlt2qgzz9zsuahngg8cmpkfl4` |
| Pair validator hash (`client-a`) | `4388b40787d61e7b29fa2715d0fc4d6d553109c13698ea931e520312` |
| Pair validator address (`client-a`) | `addr_test1wppc3dq8sltpu7eflgn3t58uf4k42vgfcymf365nrefqxyshd2j73` |

### Final UTxO states

| Artifact | Field | Value |
| --- | --- | --- |
| Receiver | balance | 21.000000 ADA |
| Receiver | accrued_to_hook | 0.000000 ADA |
| Receiver | min_utxo | 5.000000 ADA |
| PaymentHook | accrued_fees | 24.000000 ADA |
| PaymentHook | lifetime_collected | 34.000000 ADA |
| PaymentHook | lifetime_withdrawn | 10.000000 ADA |
| PaymentHook | min_utxo | 5.000000 ADA |

### Pair final prices

| Pair | Final price (scaled) | Updated via |
| --- | --- | --- |
| ADA/USD | `751000000` | batch (step 25, 6 pairs) |
| BNB/USD | `61500000000` | single create (step 13–23) |
| BTC/USD | `6001000000000` | batch (step 25, 6 pairs) |
| DAI/USD | `100100345` | batch (step 25, 6 pairs) |
| DOT/USD | `420000000` | single create (step 13–23) |
| ETH/USD | `250100000000` | batch (step 25, 6 pairs) |
| MATIC/USD | `980000000` | single create (step 13–23) |
| SOL/USD | `18510000000` | batch (step 25, 6 pairs) |
| USDC/USD | `100045678` | single create (step 13–23) |
| USDT/USD | `100101234` | batch (step 25, 6 pairs) |
| XRP/USD | `520000000` | single create (step 13–23) |

## Key transaction explorer links (Preview CExplorer)

| Operation | Tx hash | Explorer |
| --- | --- | --- |
| Config bootstrap | `7c38e74527bb3b9ad66356f91c7fa9530c9043a7328ba9dd180f6313d48e15a9` | [CExplorer](https://preview.cexplorer.io/tx/7c38e74527bb3b9ad66356f91c7fa9530c9043a7328ba9dd180f6313d48e15a9) |
| PaymentHook bootstrap | `0585599bec05f50104ed5fe1c0ef76e858f560352a94ba2c67f18fac4670a739` | [CExplorer](https://preview.cexplorer.io/tx/0585599bec05f50104ed5fe1c0ef76e858f560352a94ba2c67f18fac4670a739) |
| Receiver bootstrap (`client-a`) | `1cdfe637c8a242e9f381de1582fabeb53075c66ff8044c2e3a5909080ca123e4` | [CExplorer](https://preview.cexplorer.io/tx/1cdfe637c8a242e9f381de1582fabeb53075c66ff8044c2e3a5909080ca123e4) |
| Publish client reference scripts (Receiver+Pair+PairMint) | `3e813d0e6b0b9f0b6990e36c0754c78b21a2557fe9d1b0214829b02fde26c60d` | [CExplorer](https://preview.cexplorer.io/tx/3e813d0e6b0b9f0b6990e36c0754c78b21a2557fe9d1b0214829b02fde26c60d) |
| First single-pair update (USDC/USD) | `e117bb14e065387b1fc87b0ede4160679a201588c26c15807846897574c2a391` | [CExplorer](https://preview.cexplorer.io/tx/e117bb14e065387b1fc87b0ede4160679a201588c26c15807846897574c2a391) |
| Batch update (6 pairs) | `f990e95452caceb32a178d12d43a839f88c54002d4a34dec61989a2d9807a27f` | [CExplorer](https://preview.cexplorer.io/tx/f990e95452caceb32a178d12d43a839f88c54002d4a34dec61989a2d9807a27f) |
| **Settle** | `f4f667c03a11479fc341b87622a26c73cdf2dbeee09fca7ee49514988468faaa` | [CExplorer](https://preview.cexplorer.io/tx/f4f667c03a11479fc341b87622a26c73cdf2dbeee09fca7ee49514988468faaa) |
| Receiver withdraw | `3eb7f58769b5412c443d30f40edefa21f90298b347dcb89dceec2959bf789aae` | [CExplorer](https://preview.cexplorer.io/tx/3eb7f58769b5412c443d30f40edefa21f90298b347dcb89dceec2959bf789aae) |
| PaymentHook withdraw | `c9aa09065af0d8fdd300bb7f09cc43cb659a0dd948e49c44b3f4fa2e001e2468` | [CExplorer](https://preview.cexplorer.io/tx/c9aa09065af0d8fdd300bb7f09cc43cb659a0dd948e49c44b3f4fa2e001e2468) |
| Reclaim payment-hook ref script | `87df862633d85710df36b80f62277a2624467dddd19a540e2625046852995d35` | [CExplorer](https://preview.cexplorer.io/tx/87df862633d85710df36b80f62277a2624467dddd19a540e2625046852995d35) |
| Republish payment-hook ref script | `d2d5334e13778d59fb5a373a8f22327641bbed68afc7c7544ca06f31747a8150` | [CExplorer](https://preview.cexplorer.io/tx/d2d5334e13778d59fb5a373a8f22327641bbed68afc7c7544ca06f31747a8150) |

## Notes

Each DIA `OracleIntent` is generated just-in-time from the live chain tip immediately before its transaction so the signed `timestamp` and `validFrom`/`validTo` window are anchored to real network time. For the batch update, all intents are generated at the start of step 25 with a 1-hour expiry; each retry derives a fresh validity window from the chain tip at that moment.

Step 29–30 demonstrates the full reclaim + republish round-trip for the `payment-hook` reference-script UTxO: step 29 spends it back to the admin wallet; step 30 republishes it at a new outRef. This validates that `reference_holder` correctly enforces the admin-gated spend (Config signer + Config NFT as reference input).
