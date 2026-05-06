# DIA Oracle — Fee Benchmark Report

| Field        | Value |
|--------------|-------|
| Bench run    | `20260506-162133` |
| Base state   | `20260506-084452` |
| Cycles       | 5 |
| Generated    | 2026-05-06T17:53:43.940Z |

## Network Fee Summary (lovelace / ADA)

> On-chain transaction fees paid to Cardano. Protocol fees (2 ADA × pairs) are separate.

| Operation  | Samples | Avg (lovelace) | Avg (ADA)  | Min (lovelace) | Max (lovelace) |
|------------|---------|----------------|------------|----------------|----------------|
| update-1   |       5 |         770004 |   0.770004 |         769796 |         770838 |
| batch-1    |       5 |         781184 |   0.781184 |         781184 |         781184 |
| batch-2    |       5 |        1009592 |   1.009592 |        1009286 |        1009669 |
| batch-3    |       5 |        1262869 |   1.262869 |        1262758 |        1263036 |
| batch-4    |       5 |        1542638 |   1.542638 |        1542169 |        1542951 |
| batch-5    |       5 |        1847679 |   1.847679 |        1847375 |        1848895 |
| batch-6    |       5 |        2186016 |   2.186016 |        2184755 |        2186857 |

## Execution Units

> CPU steps and memory units consumed per transaction (Plutus budget).

| Operation  |       Avg CPU |       Min CPU |       Max CPU |    Avg Mem |    Min Mem |    Max Mem |
|------------|---------------|---------------|---------------|------------|------------|------------|
| update-1   |       798413942 |       797698104 |       801277294 |      2080349 |      2077630 |      2091224 |
| batch-1    |       838177015 |       838177015 |       838177015 |      2222901 |      2222901 |      2222901 |
| batch-2    |      1509087242 |      1509072389 |      1509146653 |      3922574 |      3917200 |      3923918 |
| batch-3    |      2278303133 |      2276812046 |      2280539764 |      5936514 |      5936451 |      5936609 |
| batch-4    |      3150028670 |      3146016494 |      3152703454 |      8279978 |      8276866 |      8282052 |
| batch-5    |      4117261260 |      4115123756 |      4125811276 |     10943602 |     10941005 |     10953991 |
| batch-6    |      5193571471 |      5185175150 |      5199169018 |     13943003 |     13931640 |     13950578 |

## Cardano Budget Limits & Utilization

> Per-tx execution unit limits on Cardano (Babbage/Conway era).

| Resource | Limit            | batch-6 avg    | batch-6 % used |
|----------|-----------------|----------------|----------------|
| CPU      | 10,000,000,000  |  5,193,571,471 |         51.9% |
| Memory   | 14,000,000      |     13,943,003 |        **99.6%** |

Memory is the binding constraint. batch-6 sits at ~99.6% of the memory limit — that is why batch-7 and above fail.

## Fee Estimation Model

Linear regression over batch-1 … batch-6 data (least squares):

```
fee (lovelace) ≈ 456,511 + 280,520 × N
fee (ADA)      ≈ 0.4565  +  0.2805 × N
```

where N = number of pairs in the batch.

### Predicted fees for N = 1 … 10

| N  | Predicted (lovelace) | Predicted (ADA) | Actual avg (ADA) | Error     |
|----|----------------------|-----------------|------------------|-----------|
|  1 |              737,030 |        0.737030 |         0.781184 |   +44,154 |
|  2 |            1,017,550 |        1.017550 |         1.009592 |    -7,958 |
|  3 |            1,298,070 |        1.298070 |         1.262869 |   -35,201 |
|  4 |            1,578,590 |        1.578590 |         1.542638 |   -35,952 |
|  5 |            1,859,109 |        1.859109 |         1.847679 |   -11,430 |
|  6 |            2,139,629 |        2.139629 |         2.186016 |   +46,387 |
|  7 |            2,420,149 |        2.420149 |    *(mem limit)* |         — |
|  8 |            2,700,668 |        2.700668 |    *(mem limit)* |         — |
|  9 |            2,981,188 |        2.981188 |    *(mem limit)* |         — |
| 10 |            3,261,708 |        3.261708 |    *(mem limit)* |         — |

The model fits with max ~46K lovelace (~0.046 ADA) error — acceptable for fee estimation.

## Protocol Fee Design Options

> Two separate fee flows:
> - **Network fee** (measured in this benchmark): paid by the DIA oracle wallet to the Cardano network for each submitted transaction.
> - **Protocol fee** (`PROTOCOL_FEE_LOVELACE = 2,000,000` = 2 ADA × N pairs): charged by the DIA protocol to the client, deducted from the client's receiver and accumulated in the payment hook.
>
> The table below compares options for the **protocol fee** design, using the measured network fees as the cost baseline.

| Model | Formula | Example: 1 pair | Example: 6 pairs | Notes |
|-------|---------|-----------------|------------------|-------|
| **Flat per-pair** (current) | 2 ADA × N | 2 ADA | 12 ADA | Simple; over-collects at scale |
| **Base + per-pair** | 0.5 + 0.30 × N ADA | 0.80 ADA | 2.30 ADA | Tracks real cost closely |

## Notes

- `update-1` — single oracle price update (1 pair: BTC/USD).
- `batch-N` — N simultaneous price updates in one transaction (pairs: BTC/USD … up to SOL/USD).
- Data collected on Cardano **preview** testnet.
