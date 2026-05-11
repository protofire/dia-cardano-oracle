# Milestone 1 Preview Evidence

Source of truth: [`final-cardano-milestones.md`](../../final-cardano-milestones.md).

Scope: Milestone 1 validation on Cardano Preview. Cardano mainnet deployment and final mainnet evidence are not included here.

Verification date: **20260511-1** (chain walk + local tooling, current bytecode).

Network: Cardano Preview.

Evidence pack location: [`docs/milestones/evidence/m1-preview-20260511-135140/`](./) — captured logs for every CLI step plus `SUMMARY.json` with the final on-chain state.

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

The integration exercises **eleven price pairs** (`USDC/USD`, `BTC/USD`, `ETH/USD`, `ADA/USD`, `USDT/USD`, `DAI/USD`, `SOL/USD`, `BNB/USD`, `XRP/USD`, `MATIC/USD`, `DOT/USD`). All eleven are bootstrapped via individual `preview:update` transactions. A subsequent batch transaction updates the first 7 non-USDC pairs in one `preview:update:batch` call.

### Protocol bootstrap (one-time)

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 1 | `preview:protocol:init` | *(local artifact)* | — | [`01-protocol-init.log`](./01-protocol-init.log) |
| 2 | `preview:config:parameterize` | *(local artifact)* | — | [`02-config-parameterize.log`](./02-config-parameterize.log) |
| 3 | `preview:config:bootstrap` | `70d801e6b0f74d0034f90713fcd7b1ee5ee1e4e8f4f6bd8b66ca5c7df6378891` | 0.301025 ADA | [`03-config-bootstrap.log`](./03-config-bootstrap.log) |
| 4 | `preview:config:reference-scripts` (Config+Coordinator) | `c0b5bc64cb285445e7d133366e68f142c1af4be87548a72f9c1f61e1fc26302c` | 0.610561 ADA | [`04-config-reference-scripts.log`](./04-config-reference-scripts.log) |
| 5 | `preview:payment-hook:parameterize` | *(local artifact)* | — | [`05-payment-hook-parameterize.log`](./05-payment-hook-parameterize.log) |
| 6 | `preview:payment-hook:bootstrap` | `fee6edd61513b125969f2d3fabc6d483ef6f1af7efc5142b7169554c094278fe` | 0.600798 ADA | [`06-payment-hook-bootstrap.log`](./06-payment-hook-bootstrap.log) |
| 7 | `preview:payment-hook:reference-script` | `b1f59210e68a3eaedba54a9f05fed77db8d947c9d928b4011762b3bb1a0e147f` | 0.388933 ADA | [`07-payment-hook-reference-script.log`](./07-payment-hook-reference-script.log) |

### Client onboarding (`client-a`)

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 8 | `preview:client:init` | *(local artifact)* | — | [`08-client-init.log`](./08-client-init.log) |
| 9 | `preview:receiver:parameterize` | *(local artifact)* | — | [`09-receiver-parameterize.log`](./09-receiver-parameterize.log) |
| 10 | `preview:receiver:bootstrap` | `0e22784c7b1b6a9eb63a7bff90ce4bb137a51cd126c6621072e72f5a9d44fc7b` | 0.436028 ADA | [`10-receiver-bootstrap.log`](./10-receiver-bootstrap.log) |
| 11 | `preview:reference-scripts:publish-client` (Receiver+Pair+PairMint) | `5ede9be2a60192aa016bd7eb9bc000443537a05d906ed17f3bdf2f3a050a788f` | 0.776309 ADA | [`11-client-reference-scripts.log`](./11-client-reference-scripts.log) |
| 12 | `preview:receiver:top-up` (top-up 1) | `64a67bd90eaa4b21e7084b2ed94d0db4a4c30d7c27aa5148bfb1d35681907cf3` | 0.356644 ADA | [`12-receiver-top-up.log`](./12-receiver-top-up.log) |

### Single-pair pair-create updates — 11 pairs via `preview:update`

| Step | Pair | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 13 | USDC/USD | `dd4edf8f0ebe6b69ca007ac88089a9503ee155dd8e4cab82fa6d55fd91a3216e` | 0.778209 ADA | [`13-update-usdc-bootstrap.log`](./13-update-usdc-bootstrap.log) |
| 14 | BTC/USD | `1c687712be2d12272394dd6a05d70b501e99b2b40a71f33ce5f7d951706114c3` | 0.778473 ADA | [`14-bootstrap-btc-usd.log`](./14-bootstrap-btc-usd.log) |
| 15 | ETH/USD | `9f469a432cab9a84a0b0cf3257619c411948826d2e6494c19df58f69202bdfa3` | 0.778473 ADA | [`15-bootstrap-eth-usd.log`](./15-bootstrap-eth-usd.log) |
| 16 | ADA/USD | `02f9fea591b0d10b255e14a97d2387ff75b58fcf683a3cde26278c49fc497279` | 0.778121 ADA | [`16-bootstrap-ada-usd.log`](./16-bootstrap-ada-usd.log) |
| 17 | USDT/USD | `a74134f4ec35b40990e4c0b3227ec9eef8261bb9c4c22f60f57360ecf2a51407` | 0.778209 ADA | [`17-bootstrap-usdt-usd.log`](./17-bootstrap-usdt-usd.log) |
| 18 | DAI/USD | `bc74057af2450626d70cf680c09912815ba8059d47a3899aae8b37d7ab8161a3` | 0.778121 ADA | [`18-bootstrap-dai-usd.log`](./18-bootstrap-dai-usd.log) |
| 19 | SOL/USD | `1ee8cea5c90b0c6eb0fa47d8b966de7929a75054074513631d84c175a3fc0a2b` | 0.778473 ADA | [`19-bootstrap-sol-usd.log`](./19-bootstrap-sol-usd.log) |
| 20 | BNB/USD | `d1ed6163a3c3eaaf27d352b83d78d2f6616f13940e2c567830cafe42cbf286e3` | 0.778473 ADA | [`20-bootstrap-bnb-usd.log`](./20-bootstrap-bnb-usd.log) |
| 21 | XRP/USD | `1a23ca96fce9ddcf7ea265de246468dfde0b3206e387fe6ec108bc6f29b23a68` | 0.778121 ADA | [`21-bootstrap-xrp-usd.log`](./21-bootstrap-xrp-usd.log) |
| 22 | MATIC/USD | `e7cc33e6ef8e86989c3bdbfb5c5401fd9dc2f5fde6ff68edbec8c08a000a77f0` | 0.778303 ADA | [`22-bootstrap-matic-usd.log`](./22-bootstrap-matic-usd.log) |
| 23 | DOT/USD | `36ed5cf372b13e9d3f0b2693dc280d954f3283967384941782b6b549f47df3ff` | 0.778121 ADA | [`23-bootstrap-dot-usd.log`](./23-bootstrap-dot-usd.log) |

### Second top-up (replenish before batch)

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 24 | `preview:receiver:top-up` (top-up 2) | `2d2566000231a2cc825334a948299ec64341bf590838ee824eb7ff5bf7883722` | 0.356820 ADA | [`24-receiver-top-up-2.log`](./24-receiver-top-up-2.log) |

### Batch update — coordinator `ApplyBatch`

Batch sizes 10, 9, 8 were attempted first but exceeded the per-tx Plutus ExUnits budget (each secp256k1 ECDSA verification costs ~440M CPU steps; beyond 7 verifications the batch surpasses the ~10B per-tx ceiling). Batch size **7** succeeded.

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| `preview:update:batch` (10 pairs, attempted) | *(ExUnits over budget — not submitted)* | 0 ADA | [`25-update-batch-10.log`](./25-update-batch-10.log) |
| `preview:update:batch` (9 pairs, attempted) | *(ExUnits over budget — not submitted)* | 0 ADA | [`25-update-batch-9.log`](./25-update-batch-9.log) |
| `preview:update:batch` (8 pairs, attempted) | *(ExUnits over budget — not submitted)* | 0 ADA | [`25-update-batch-8.log`](./25-update-batch-8.log) |
| 25 | `preview:update:batch` (7 pairs) | `b8af6081fe715745870a996243766cea7a23fbfe7c38b2de85e6c31d38dd6fd8` | 2.489214 ADA | [`25-update-batch-7.log`](./25-update-batch-7.log) |

### Settle, withdrawals, reclaim + republish reference script

| Step | Operation | Tx hash | Fee | Log |
| --- | --- | --- | --- | --- |
| 26 | `preview:settle` | `3b634df3fbc01e47411e6ca7d3f7f5cfe2bd60adb4686e013858dea21b32abf8` | 0.776002 ADA | [`26-settle.log`](./26-settle.log) |
| 27 | `preview:receiver:withdraw` | `1334a089836efab5a87b6d1cdd2f79c14a19cf3b934bfff79a576bcdc9119f54` | 0.388903 ADA | [`27-receiver-withdraw.log`](./27-receiver-withdraw.log) |
| 28 | `preview:payment-hook:withdraw` | `2d21224eafd4976bf65ab39bc29fa9ec4e63316d4bf2e313005f164fc60e9e62` | 0.380690 ADA | [`28-payment-hook-withdraw.log`](./28-payment-hook-withdraw.log) |
| 29 | `preview:reclaim-reference-script --script payment-hook` | `0d28bd58fea59dfefc241f569676a6e685fe2eaa1fe07b5024e3a8ab04c0eba0` | 0.312663 ADA | [`29-reclaim-payment-hook-reference-script.log`](./29-reclaim-payment-hook-reference-script.log) |
| 30 | `preview:payment-hook:reference-script` (republish) | `58c4b04762b5f534acb5e5c60fe2e8c11a68c4d19fda2fcf5903950007cc1441` | 0.388933 ADA | [`30-republish-payment-hook-reference-script.log`](./30-republish-payment-hook-reference-script.log) |

## ADA flow summary

Single wallet used for all operations (DIA admin = updater = funder).

| Item | Value |
| --- | --- |
| Wallet address | `addr_test1qpgpsm75w7l9u6au7shqzsaulrtxz2gp6xw9zhun70es6tt4t3wsjavx26kmh586erf8xxhqc2y7urq5az32sjv56nyqquxj3j` |
| Initial wallet balance | **4807.133756 ADA** (4,807,133,756 lovelace) |
| Final wallet balance | **4543.597076 ADA** (4,543,597,076 lovelace) |
| Total on-chain fees paid | **17.124620 ADA** (17,124,620 lovelace) |
| Net ADA locked in protocol | **246.412060 ADA** (initial − final − fees) |

### ADA locked breakdown

| Location | ADA locked |
| --- | --- |
| Config UTxO (min-UTxO) | 5.000000 ADA |
| PaymentHook UTxO (min-UTxO + accrued) | 9.400000 ADA |
| Receiver UTxO (min-UTxO + balance + accrued) | 45.600000 ADA |
| Pair UTxOs × 11 (min-UTxO each) | 55.000000 ADA |
| Reference-script UTxOs × 6 (config+coordinator+hook+receiver+pair+pairMint) | 129.412060 ADA |
| **Total locked in protocol** | **244.412060 ADA** |

Reference-script min-UTxO breakdown: `configValidator`=10.667250 ADA, `coordinatorValidator`=34.294670 ADA, `paymentHookValidator`=22.562850 ADA, `receiverValidator`=23.217970 ADA, `pairValidator`=19.334660 ADA, `pairMintPolicy`=19.334660 ADA.

## On-chain fee audit

| Step | Operation | Tx hash (first 16 chars) | Fee paid |
| --- | --- | --- | --- |
| `preview:config:bootstrap` | `70d801e6b0f74d00…` | 0.301025 ADA |
| `preview:config:reference-scripts` (Config+Coordinator) | `c0b5bc64cb285445…` | 0.610561 ADA |
| `preview:payment-hook:bootstrap` | `fee6edd61513b125…` | 0.600798 ADA |
| `preview:payment-hook:reference-script` | `b1f59210e68a3eae…` | 0.388933 ADA |
| `preview:receiver:bootstrap` | `0e22784c7b1b6a9e…` | 0.436028 ADA |
| `preview:reference-scripts:publish-client` (Receiver+Pair+PairMint) | `5ede9be2a60192aa…` | 0.776309 ADA |
| `preview:receiver:top-up` (top-up 1) | `64a67bd90eaa4b21…` | 0.356644 ADA |
| `preview:update` — USDC/USD create | `dd4edf8f0ebe6b69…` | 0.778209 ADA |
| `preview:update` — BTC/USD create | `1c687712be2d1227…` | 0.778473 ADA |
| `preview:update` — ETH/USD create | `9f469a432cab9a84…` | 0.778473 ADA |
| `preview:update` — ADA/USD create | `02f9fea591b0d10b…` | 0.778121 ADA |
| `preview:update` — USDT/USD create | `a74134f4ec35b409…` | 0.778209 ADA |
| `preview:update` — DAI/USD create | `bc74057af2450626…` | 0.778121 ADA |
| `preview:update` — SOL/USD create | `1ee8cea5c90b0c6e…` | 0.778473 ADA |
| `preview:update` — BNB/USD create | `d1ed6163a3c3eaaf…` | 0.778473 ADA |
| `preview:update` — XRP/USD create | `1a23ca96fce9ddcf…` | 0.778121 ADA |
| `preview:update` — MATIC/USD create | `e7cc33e6ef8e8698…` | 0.778303 ADA |
| `preview:update` — DOT/USD create | `36ed5cf372b13e9d…` | 0.778121 ADA |
| `preview:receiver:top-up` (top-up 2) | `2d2566000231a2cc…` | 0.356820 ADA |
| `preview:update:batch` (7 pairs) | `b8af6081fe715745…` | 2.489214 ADA |
| `preview:settle` | `3b634df3fbc01e47…` | 0.776002 ADA |
| `preview:receiver:withdraw` | `1334a089836efab5…` | 0.388903 ADA |
| `preview:payment-hook:withdraw` | `2d21224eafd4976b…` | 0.380690 ADA |
| `preview:reclaim-reference-script --script payment-hook` | `0d28bd58fea59dfe…` | 0.312663 ADA |
| `preview:payment-hook:reference-script` (republish) | `58c4b04762b5f534…` | 0.388933 ADA |

**Total confirmed on-chain fees: 17.124620 ADA** (17,124,620 lovelace).

## Final on-chain state

Snapshot from [`SUMMARY.json`](./SUMMARY.json) at the end of the Preview chain walk.

### Script identities (current bytecode)

| Item | Value |
| --- | --- |
| Reference-holder address | `addr_test1wztwp228gz6893mnzsqu4va98y7hw7zany0htw5xf509cxqp3vhhp` |
| Config policy ID / validator hash | `bbf4943b7c093a147db118bf9eeb762e0d20e758290f3833471a14f8` |
| Config NFT unit | `bbf4943b7c093a147db118bf9eeb762e0d20e758290f3833471a14f84449415f434f4e464947` |
| Coordinator stake validator hash | `0cf516f3efc54b66a421b9cee4bee8aa1aa9446261f94c751e99432d` |
| PaymentHook policy ID / validator hash | `7b7c7ac1b2c7bdaa32a087ecfb9e0e04452503c4bdce87f9e98b4e30` |
| PaymentHook NFT unit | `7b7c7ac1b2c7bdaa32a087ecfb9e0e04452503c4bdce87f9e98b4e304449415f5041594d454e545f484f4f4b` |
| Receiver validator hash (`client-a`) | `13605a0cbf39ab67adcc40e7332d99a15c27d54ecdd0c89a05eca34f` |
| Receiver validator address (`client-a`) | `addr_test1wqfkqksvhuu6keade3qwwvednxs4cf74fmxapjy6qhk2xnc92mxpz` |
| Pair validator hash (`client-a`) | `389979173965c6ef1e325eefb88ba55b36af19c5c7a0e732e686d49c` |
| Pair validator address (`client-a`) | `addr_test1wqufj7gh89judmc7xf0wlwyt54dndtcechr6peeju6rdf8q90lu6e` |

### Final UTxO states

| Artifact | Field | Value |
| --- | --- | --- |
| Receiver | balance | 40.600000 ADA |
| Receiver | accrued_to_hook | 0.000000 ADA |
| Receiver | min_utxo | 5.000000 ADA |
| PaymentHook | accrued_fees | 4.400000 ADA |
| PaymentHook | lifetime_collected | 14.400000 ADA |
| PaymentHook | lifetime_withdrawn | 10.000000 ADA |
| PaymentHook | min_utxo | 5.000000 ADA |

### Pair final prices

| Pair | Final price (scaled) | Updated via |
| --- | --- | --- |
| ADA/USD | `751000000` | batch (step 25, 7 pairs) |
| BNB/USD | `61510000000` | batch (step 25, 7 pairs) |
| BTC/USD | `6001000000000` | batch (step 25, 7 pairs) |
| DAI/USD | `100100345` | batch (step 25, 7 pairs) |
| DOT/USD | `420000000` | single create (step 13–23) |
| ETH/USD | `250100000000` | batch (step 25, 7 pairs) |
| MATIC/USD | `980000000` | single create (step 13–23) |
| SOL/USD | `18510000000` | batch (step 25, 7 pairs) |
| USDC/USD | `100045678` | single create (step 13–23) |
| USDT/USD | `100101234` | batch (step 25, 7 pairs) |
| XRP/USD | `520000000` | single create (step 13–23) |

## Key transaction explorer links (Preview CExplorer)

| Operation | Tx hash | Explorer |
| --- | --- | --- |
| Config bootstrap | `70d801e6b0f74d0034f90713fcd7b1ee5ee1e4e8f4f6bd8b66ca5c7df6378891` | [CExplorer](https://preview.cexplorer.io/tx/70d801e6b0f74d0034f90713fcd7b1ee5ee1e4e8f4f6bd8b66ca5c7df6378891) |
| PaymentHook bootstrap | `fee6edd61513b125969f2d3fabc6d483ef6f1af7efc5142b7169554c094278fe` | [CExplorer](https://preview.cexplorer.io/tx/fee6edd61513b125969f2d3fabc6d483ef6f1af7efc5142b7169554c094278fe) |
| Receiver bootstrap (`client-a`) | `0e22784c7b1b6a9eb63a7bff90ce4bb137a51cd126c6621072e72f5a9d44fc7b` | [CExplorer](https://preview.cexplorer.io/tx/0e22784c7b1b6a9eb63a7bff90ce4bb137a51cd126c6621072e72f5a9d44fc7b) |
| Publish client reference scripts (Receiver+Pair+PairMint) | `5ede9be2a60192aa016bd7eb9bc000443537a05d906ed17f3bdf2f3a050a788f` | [CExplorer](https://preview.cexplorer.io/tx/5ede9be2a60192aa016bd7eb9bc000443537a05d906ed17f3bdf2f3a050a788f) |
| First single-pair update (USDC/USD) | `dd4edf8f0ebe6b69ca007ac88089a9503ee155dd8e4cab82fa6d55fd91a3216e` | [CExplorer](https://preview.cexplorer.io/tx/dd4edf8f0ebe6b69ca007ac88089a9503ee155dd8e4cab82fa6d55fd91a3216e) |
| Batch update (7 pairs) | `b8af6081fe715745870a996243766cea7a23fbfe7c38b2de85e6c31d38dd6fd8` | [CExplorer](https://preview.cexplorer.io/tx/b8af6081fe715745870a996243766cea7a23fbfe7c38b2de85e6c31d38dd6fd8) |
| **Settle** | `3b634df3fbc01e47411e6ca7d3f7f5cfe2bd60adb4686e013858dea21b32abf8` | [CExplorer](https://preview.cexplorer.io/tx/3b634df3fbc01e47411e6ca7d3f7f5cfe2bd60adb4686e013858dea21b32abf8) |
| Receiver withdraw | `1334a089836efab5a87b6d1cdd2f79c14a19cf3b934bfff79a576bcdc9119f54` | [CExplorer](https://preview.cexplorer.io/tx/1334a089836efab5a87b6d1cdd2f79c14a19cf3b934bfff79a576bcdc9119f54) |
| PaymentHook withdraw | `2d21224eafd4976bf65ab39bc29fa9ec4e63316d4bf2e313005f164fc60e9e62` | [CExplorer](https://preview.cexplorer.io/tx/2d21224eafd4976bf65ab39bc29fa9ec4e63316d4bf2e313005f164fc60e9e62) |
| Reclaim payment-hook ref script | `0d28bd58fea59dfefc241f569676a6e685fe2eaa1fe07b5024e3a8ab04c0eba0` | [CExplorer](https://preview.cexplorer.io/tx/0d28bd58fea59dfefc241f569676a6e685fe2eaa1fe07b5024e3a8ab04c0eba0) |
| Republish payment-hook ref script | `58c4b04762b5f534acb5e5c60fe2e8c11a68c4d19fda2fcf5903950007cc1441` | [CExplorer](https://preview.cexplorer.io/tx/58c4b04762b5f534acb5e5c60fe2e8c11a68c4d19fda2fcf5903950007cc1441) |

## Notes

Each DIA `OracleIntent` is generated just-in-time from the live chain tip immediately before its transaction so the signed `timestamp` and `validFrom`/`validTo` window are anchored to real network time. For the batch update, all intents are generated at the start of step 25 with a 1-hour expiry; each retry derives a fresh validity window from the chain tip at that moment.

Step 29–30 demonstrates the full reclaim + republish round-trip for the `payment-hook` reference-script UTxO: step 29 spends it back to the admin wallet; step 30 republishes it at a new outRef. This validates that `reference_holder` correctly enforces the admin-gated spend (Config signer + Config NFT as reference input).
