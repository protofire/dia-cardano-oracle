# Milestone 1 Preview Evidence

Source of truth: [`final-cardano-milestones.md`](../../final-cardano-milestones.md).

Scope: Milestone 1 validation on Cardano Preview.

Verification date: **20260516-0** (chain walk + local tooling, current bytecode).

Network: Cardano Preview.

Evidence pack location: [`docs/milestones/evidence/m1-preview-20260516-090057/`](./) — captured logs for every CLI step plus `SUMMARY.json` with the final on-chain state.

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

The integration exercises **eleven price pairs** (`USDC/USD`, `BTC/USD`, `ETH/USD`, `ADA/USD`, `USDT/USD`, `DAI/USD`, `SOL/USD`, `BNB/USD`, `XRP/USD`, `MATIC/USD`, `DOT/USD`). All eleven are bootstrapped via individual `update` transactions. A subsequent batch transaction updates the first 10 non-USDC pairs in one `update:batch` call.

### Protocol bootstrap (one-time)

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 1 | `protocol:init` | *(local artifact)* | — | [`01-protocol-init.log`](./01-protocol-init.log) |
| 2 | `config:parameterize` | *(local artifact)* | — | [`02-config-parameterize.log`](./02-config-parameterize.log) |
| 3 | `config:bootstrap` | `32c073411da8987189e64a049d39c2f974d84359d54b1f3e5a5871de9a108361` | 0.300680 ADA | [`03-config-bootstrap.log`](./03-config-bootstrap.log) |
| 4 | `config:reference-scripts` (Config+Coordinator) | `6c88f89d26b03cd5192542d7db91ec6f77c28214861b72dbfa04f31796a9d94f` | 0.624773 ADA | [`04-config-reference-scripts.log`](./04-config-reference-scripts.log) |
| 5 | `payment-hook:parameterize` | *(local artifact)* | — | [`05-payment-hook-parameterize.log`](./05-payment-hook-parameterize.log) |
| 6 | `payment-hook:bootstrap` | `7045f874c46651653ed56c10d30b4b7260c5b3b2d87a4b9964d1f95928bd27ad` | 0.593830 ADA | [`06-payment-hook-bootstrap.log`](./06-payment-hook-bootstrap.log) |
| 7 | `payment-hook:reference-script` | `043ae2a1cd698df137881c4dd22c2f8bf3a441e02cbb64cd1ece7521f5570010` | 0.382113 ADA | [`07-payment-hook-reference-script.log`](./07-payment-hook-reference-script.log) |

### Client onboarding (`client-a`)

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 8 | `client:init` | *(local artifact)* | — | [`08-client-init.log`](./08-client-init.log) |
| 9 | `receiver:parameterize` | *(local artifact)* | — | [`09-receiver-parameterize.log`](./09-receiver-parameterize.log) |
| 10 | `receiver:bootstrap` | `adc2879bede0c4cf41c844f51042a9ee9f481927f5c1b148c8da3e7ea0198eae` | 0.429296 ADA | [`10-receiver-bootstrap.log`](./10-receiver-bootstrap.log) |
| 11 | `reference-scripts:publish-client` (Receiver+Pair+PairMint) | `06ad7adcb4cd71b80b3d00b9e7cf70fb0f140a20b0f430463df913178c1cebe0` | 0.817713 ADA | [`11-client-reference-scripts.log`](./11-client-reference-scripts.log) |
| 12 | `receiver:top-up` (top-up 1) | `ae4b80f39d4f2ef731c59cb437b695b96f62cb88e3f52b13d6cb1d399e3096a0` | 0.352374 ADA | [`12-receiver-top-up.log`](./12-receiver-top-up.log) |

### Single-pair pair-create updates — 11 pairs via `update`

| Step | Pair | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 13 | USDC/USD | `2e5cf371b701016c89d2390abf387a545854fe1cf84e1e9b0483926f2663f0b8` | 0.797529 ADA | [`13-update-usdc-bootstrap.log`](./13-update-usdc-bootstrap.log) |
| 14 | BTC/USD | `23912c205d099490c1400656eca0df2ae63a96f5d472e6793ea96de3bd0d9639` | 0.797793 ADA | [`14-bootstrap-btc-usd.log`](./14-bootstrap-btc-usd.log) |
| 15 | ETH/USD | `7c260bb19bac3788957bcf190e953cbfdb1da19deb005ce6f57d1c5193dbdaa6` | 0.797793 ADA | [`15-bootstrap-eth-usd.log`](./15-bootstrap-eth-usd.log) |
| 16 | ADA/USD | `b365f77a68b86d041a486fc48de0d1b18d6278732a49aa9f8f29dab9b793acc7` | 0.797441 ADA | [`16-bootstrap-ada-usd.log`](./16-bootstrap-ada-usd.log) |
| 17 | USDT/USD | `4f05d6add5737a241261b70bbc2cf7f6104383e9840fbb17cf55ec069309c61f` | 0.797529 ADA | [`17-bootstrap-usdt-usd.log`](./17-bootstrap-usdt-usd.log) |
| 18 | DAI/USD | `b22470ee2394474b5b5da30a59d7c1efe8a6ba84ec7adee7214e27dcd2fd4131` | 0.797441 ADA | [`18-bootstrap-dai-usd.log`](./18-bootstrap-dai-usd.log) |
| 19 | SOL/USD | `cde1e4757a9145deb4a592edf47b89a971d06e014743b4d7a387a3898c92da70` | 0.797793 ADA | [`19-bootstrap-sol-usd.log`](./19-bootstrap-sol-usd.log) |
| 20 | BNB/USD | `dbce590b9e4458f855df435b991619830902d25b0b9ae778db145c53103437f4` | 0.797793 ADA | [`20-bootstrap-bnb-usd.log`](./20-bootstrap-bnb-usd.log) |
| 21 | XRP/USD | `a8029eec7e4d183b90b43f96ca6a1ebf4e03f78bee6851ec7f7911041bd971ae` | 0.797441 ADA | [`21-bootstrap-xrp-usd.log`](./21-bootstrap-xrp-usd.log) |
| 22 | MATIC/USD | `576f59e04cc2b3af2480665a47ab7745e3284e0e49fe4a78b9cb0469adf04b04` | 0.797623 ADA | [`22-bootstrap-matic-usd.log`](./22-bootstrap-matic-usd.log) |
| 23 | DOT/USD | `2b7045bb706039c03ee4305da877146db4fd9d8a5cf17a27b10057b42a1fbbf1` | 0.797441 ADA | [`23-bootstrap-dot-usd.log`](./23-bootstrap-dot-usd.log) |

### Second top-up (replenish before batch)

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 24 | `receiver:top-up` (top-up 2) | `7a2db508da1587b85f8d0142f690f55405391ac080bec19239963f8e34e2808c` | 0.352119 ADA | [`24-receiver-top-up-2.log`](./24-receiver-top-up-2.log) |

### Batch update — coordinator `ApplyBatch`

Batch size **10** succeeded.

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |

| 25 | `update:batch` (10 pairs) | `4530b27661ceb105ea37dd4fea122fcd012a38feeb96ef9ca806fb4f852466d5` | 2.666824 ADA | [`25-update-batch-10.log`](./25-update-batch-10.log) |

### Settle, withdrawals, reclaim + republish reference script, pair burn

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 26 | `settle` | `a4ebb3952b31c27ac49af93e40f7bc1f14bec81195978fddf164af26c992a66f` | 0.771381 ADA | [`26-settle.log`](./26-settle.log) |
| 27 | `receiver:withdraw` | `905d5bddd20f9c67e8cb572509106c8377457d0c4d69d79393a98baa663b2e59` | 0.384162 ADA | [`27-receiver-withdraw.log`](./27-receiver-withdraw.log) |
| 28 | `payment-hook:withdraw` | `98b6fd5f786750e83ac86eb751b9045bab944ef4c33c1be275fb5bb687240539` | 0.375808 ADA | [`28-payment-hook-withdraw.log`](./28-payment-hook-withdraw.log) |
| 29 | `reclaim-reference-script --script payment-hook` | `8f7df2581263dfc2a996191f189c51020a4079c6425b635419d02b77d1470d9f` | 0.310222 ADA | [`29-reclaim-payment-hook-reference-script.log`](./29-reclaim-payment-hook-reference-script.log) |
| 30 | `payment-hook:reference-script` (republish) | `3af039c3ed90a1dd02781c796a083c8851810e5299f2f3ac953c475bb519738d` | 0.382113 ADA | [`30-republish-payment-hook-reference-script.log`](./30-republish-payment-hook-reference-script.log) |
| 31 | `pair:burn` — DOT/USD burn (admin-gated) | `ee0bf5916232273b403a8bfe37bec7bf9d09bd86498fe5003bb03b24f2268c6d` | 0.441136 ADA | [`31-pair-burn-dot-usd.log`](./31-pair-burn-dot-usd.log) |

## ADA flow summary

Single wallet used for all operations (DIA admin = updater = funder).

| Item | Value |
| --- | --- |
| Wallet address | `addr_test1qpgpsm75w7l9u6au7shqzsaulrtxz2gp6xw9zhun70es6tt4t3wsjavx26kmh586erf8xxhqc2y7urq5az32sjv56nyqquxj3j` |
| Initial wallet balance | **3399.218639 ADA** (3,399,218,639 lovelace) |
| Final wallet balance | **3135.016908 ADA** (3,135,016,908 lovelace) |
| Total on-chain fees paid | **17.958161 ADA** (17,958,161 lovelace) |
| Net ADA locked in protocol | **246.243570 ADA** (initial − final − fees) |

### ADA locked breakdown

| Location | ADA locked |
| --- | --- |
| Config UTxO (min-UTxO) | 5.000000 ADA |
| PaymentHook UTxO (min-UTxO + accrued) | 7.450000 ADA |
| Receiver UTxO (min-UTxO + balance + accrued) | 47.550000 ADA |
| Pair UTxOs × 10 (min-UTxO each; 1 burned excluded) | 50.000000 ADA |
| Reference-script UTxOs × 6 (config+coordinator+hook+receiver+pair+pairMint) | 134.243570 ADA |
| **Total locked in protocol** | **244.243570 ADA** |

Reference-script min-UTxO breakdown: `configValidator`=10.667250 ADA, `coordinatorValidator`=35.704040 ADA, `paymentHookValidator`=21.912040 ADA, `receiverValidator`=22.593020 ADA, `pairValidator`=21.683610 ADA, `pairMintPolicy`=21.683610 ADA.

## On-chain fee audit

| Step | Operation | Tx hash (first 16 chars) | Fee paid |
| --- | --- | --- | --- |
| `config:bootstrap` | `32c073411da89871…` | 0.300680 ADA |
| `config:reference-scripts` (Config+Coordinator) | `6c88f89d26b03cd5…` | 0.624773 ADA |
| `payment-hook:bootstrap` | `7045f874c4665165…` | 0.593830 ADA |
| `payment-hook:reference-script` | `043ae2a1cd698df1…` | 0.382113 ADA |
| `receiver:bootstrap` | `adc2879bede0c4cf…` | 0.429296 ADA |
| `reference-scripts:publish-client` (Receiver+Pair+PairMint) | `06ad7adcb4cd71b8…` | 0.817713 ADA |
| `receiver:top-up` (top-up 1) | `ae4b80f39d4f2ef7…` | 0.352374 ADA |
| `update` — USDC/USD create | `2e5cf371b701016c…` | 0.797529 ADA |
| `update` — BTC/USD create | `23912c205d099490…` | 0.797793 ADA |
| `update` — ETH/USD create | `7c260bb19bac3788…` | 0.797793 ADA |
| `update` — ADA/USD create | `b365f77a68b86d04…` | 0.797441 ADA |
| `update` — USDT/USD create | `4f05d6add5737a24…` | 0.797529 ADA |
| `update` — DAI/USD create | `b22470ee2394474b…` | 0.797441 ADA |
| `update` — SOL/USD create | `cde1e4757a9145de…` | 0.797793 ADA |
| `update` — BNB/USD create | `dbce590b9e4458f8…` | 0.797793 ADA |
| `update` — XRP/USD create | `a8029eec7e4d183b…` | 0.797441 ADA |
| `update` — MATIC/USD create | `576f59e04cc2b3af…` | 0.797623 ADA |
| `update` — DOT/USD create | `2b7045bb706039c0…` | 0.797441 ADA |
| `receiver:top-up` (top-up 2) | `7a2db508da1587b8…` | 0.352119 ADA |
| `update:batch` (10 pairs) | `4530b27661ceb105…` | 2.666824 ADA |
| `settle` | `a4ebb3952b31c27a…` | 0.771381 ADA |
| `receiver:withdraw` | `905d5bddd20f9c67…` | 0.384162 ADA |
| `payment-hook:withdraw` | `98b6fd5f786750e8…` | 0.375808 ADA |
| `reclaim-reference-script --script payment-hook` | `8f7df2581263dfc2…` | 0.310222 ADA |
| `payment-hook:reference-script` (republish) | `3af039c3ed90a1dd…` | 0.382113 ADA |
| `pair:burn` — DOT/USD burn (admin-gated) | `ee0bf5916232273b…` | 0.441136 ADA |

**Total confirmed on-chain fees: 17.958161 ADA** (17,958,161 lovelace).

## Final on-chain state

Snapshot from [`SUMMARY.json`](./SUMMARY.json) at the end of the Preview chain walk.

### Script identities (current bytecode)

| Item | Value |
| --- | --- |
| Reference-holder address | `addr_test1wzp0r2d4mxrdszjalz9wz4sv3nqyns8ukj3vhdsk73k3kpq46fvp2` |
| Config policy ID / validator hash | `30c7b4be816d9d4d523dee32d699abe4ea315a4f3d97d58495888274` |
| Config NFT unit | `30c7b4be816d9d4d523dee32d699abe4ea315a4f3d97d584958882744449415f434f4e464947` |
| Coordinator stake validator hash | `990107bd61178be5440d4cecf0bd21c20cd8f046897c1ef4e4b01aa4` |
| PaymentHook policy ID / validator hash | `0bab2632d30e82a227c552f2ef189277839ac4b8175b833cfdfe4160` |
| PaymentHook NFT unit | `0bab2632d30e82a227c552f2ef189277839ac4b8175b833cfdfe41604449415f5041594d454e545f484f4f4b` |
| Receiver validator hash (`client-a`) | `e6764dc87450b544fe365e5e74536258641488d33a97dbb2db5a3f1d` |
| Receiver validator address (`client-a`) | `addr_test1wrn8vnwgw3gt2387xe09uaznvfvxg9yg6vaf0kajmddr78g5wsl3w` |
| Pair validator hash (`client-a`) | `c0f62932ab92ebe5d1b01d539e597b9067ebf34aeab391de0a58cf88` |
| Pair validator address (`client-a`) | `addr_test1wrq0v2fj4wfwhew3kqw488je0wgx06lnft4t8yw7pfvvlzqlrcktv` |

### Final UTxO states

| Artifact | Field | Value |
| --- | --- | --- |
| Receiver | balance | 42.550000 ADA |
| Receiver | accrued_to_hook | 0.000000 ADA |
| Receiver | min_utxo | 5.000000 ADA |
| PaymentHook | accrued_fees | 2.450000 ADA |
| PaymentHook | lifetime_collected | 12.450000 ADA |
| PaymentHook | lifetime_withdrawn | 10.000000 ADA |
| PaymentHook | min_utxo | 5.000000 ADA |

### Pair final prices

Burned pairs are listed separately below — their on-chain Pair NFT no longer
exists and their UTxO has been spent, so the "live" table reflects only pairs
still tracked on-chain.

| Pair | Final price (scaled) | Updated via | Status |
| --- | --- | --- | --- |
| ADA/USD | `751000000` | batch (step 25, 10 pairs) | live |
| BNB/USD | `61510000000` | batch (step 25, 10 pairs) | live |
| BTC/USD | `6001000000000` | batch (step 25, 10 pairs) | live |
| DAI/USD | `100100345` | batch (step 25, 10 pairs) | live |
| DOT/USD | `421000000` | *burned (tx `ee0bf5916232273b…`)* | burned |
| ETH/USD | `250100000000` | batch (step 25, 10 pairs) | live |
| MATIC/USD | `981000000` | batch (step 25, 10 pairs) | live |
| SOL/USD | `18510000000` | batch (step 25, 10 pairs) | live |
| USDC/USD | `100045678` | single create (step 13–23) | live |
| USDT/USD | `100101234` | batch (step 25, 10 pairs) | live |
| XRP/USD | `521000000` | batch (step 25, 10 pairs) | live |

## Key transaction explorer links (Preview CExplorer)

| Operation | Tx hash | Explorer |
| --- | --- | --- |
| Config bootstrap | `32c073411da8987189e64a049d39c2f974d84359d54b1f3e5a5871de9a108361` | [CExplorer](https://preview.cexplorer.io/tx/32c073411da8987189e64a049d39c2f974d84359d54b1f3e5a5871de9a108361) |
| PaymentHook bootstrap | `7045f874c46651653ed56c10d30b4b7260c5b3b2d87a4b9964d1f95928bd27ad` | [CExplorer](https://preview.cexplorer.io/tx/7045f874c46651653ed56c10d30b4b7260c5b3b2d87a4b9964d1f95928bd27ad) |
| Receiver bootstrap (`client-a`) | `adc2879bede0c4cf41c844f51042a9ee9f481927f5c1b148c8da3e7ea0198eae` | [CExplorer](https://preview.cexplorer.io/tx/adc2879bede0c4cf41c844f51042a9ee9f481927f5c1b148c8da3e7ea0198eae) |
| Publish client reference scripts (Receiver+Pair+PairMint) | `06ad7adcb4cd71b80b3d00b9e7cf70fb0f140a20b0f430463df913178c1cebe0` | [CExplorer](https://preview.cexplorer.io/tx/06ad7adcb4cd71b80b3d00b9e7cf70fb0f140a20b0f430463df913178c1cebe0) |
| First single-pair update (USDC/USD) | `2e5cf371b701016c89d2390abf387a545854fe1cf84e1e9b0483926f2663f0b8` | [CExplorer](https://preview.cexplorer.io/tx/2e5cf371b701016c89d2390abf387a545854fe1cf84e1e9b0483926f2663f0b8) |
| Batch update (10 pairs) | `4530b27661ceb105ea37dd4fea122fcd012a38feeb96ef9ca806fb4f852466d5` | [CExplorer](https://preview.cexplorer.io/tx/4530b27661ceb105ea37dd4fea122fcd012a38feeb96ef9ca806fb4f852466d5) |
| **Settle** | `a4ebb3952b31c27ac49af93e40f7bc1f14bec81195978fddf164af26c992a66f` | [CExplorer](https://preview.cexplorer.io/tx/a4ebb3952b31c27ac49af93e40f7bc1f14bec81195978fddf164af26c992a66f) |
| Receiver withdraw | `905d5bddd20f9c67e8cb572509106c8377457d0c4d69d79393a98baa663b2e59` | [CExplorer](https://preview.cexplorer.io/tx/905d5bddd20f9c67e8cb572509106c8377457d0c4d69d79393a98baa663b2e59) |
| PaymentHook withdraw | `98b6fd5f786750e83ac86eb751b9045bab944ef4c33c1be275fb5bb687240539` | [CExplorer](https://preview.cexplorer.io/tx/98b6fd5f786750e83ac86eb751b9045bab944ef4c33c1be275fb5bb687240539) |
| Reclaim payment-hook ref script | `8f7df2581263dfc2a996191f189c51020a4079c6425b635419d02b77d1470d9f` | [CExplorer](https://preview.cexplorer.io/tx/8f7df2581263dfc2a996191f189c51020a4079c6425b635419d02b77d1470d9f) |
| Republish payment-hook ref script | `3af039c3ed90a1dd02781c796a083c8851810e5299f2f3ac953c475bb519738d` | [CExplorer](https://preview.cexplorer.io/tx/3af039c3ed90a1dd02781c796a083c8851810e5299f2f3ac953c475bb519738d) |

## Notes

Each DIA `OracleIntent` is generated just-in-time from the live chain tip immediately before its transaction so the signed `timestamp` and `validFrom`/`validTo` window are anchored to real network time. For the batch update, all intents are generated at the start of step 25 with a 1-hour expiry; each retry derives a fresh validity window from the chain tip at that moment.

Step 29–30 demonstrates the full reclaim + republish round-trip for the `payment-hook` reference-script UTxO: step 29 spends it back to the admin wallet; step 30 republishes it at a new outRef. This validates that `reference_holder` correctly enforces the admin-gated spend (Config signer + Config NFT as reference input).
