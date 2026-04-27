# Milestone 1 Preview Local Test Evidence

Captured on: 2026-04-27

These logs capture the local verification commands referenced by the Milestone 1 Preview evidence document. Each command exited with status `0`.

| Area | Working directory | Command | Log |
| --- | --- | --- | --- |
| Aiken contracts | `contracts/aiken` | `aiken check` | [`aiken-check.log`](./aiken-check.log) |
| CLI tests | `offchain/cli` | `npm run test` | [`npm-test.log`](./npm-test.log) |
| CLI typecheck | `offchain/cli` | `npm run typecheck` | [`npm-typecheck.log`](./npm-typecheck.log) |
| CLI build | `offchain/cli` | `npm run build` | [`npm-build.log`](./npm-build.log) |

Expected summary:

- `aiken check`: 24/24 Aiken tests passed.
- `npm run test`: CLI tests passed.
- `npm run typecheck`: TypeScript check completed with exit code `0`.
- `npm run build`: TypeScript build completed with exit code `0`.
