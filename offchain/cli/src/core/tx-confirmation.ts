import { getCliConfig } from "./config.js";

type AwaitTxLike = {
  awaitTx(txHash: string, checkInterval?: number): Promise<boolean>;
};

type FetchLike = typeof fetch;

type KoiosTxInfo = {
  tx_hash: string;
  block_height?: number | null;
};

class KoiosServiceDownError extends Error {
  constructor(public readonly status: number, statusText: string) {
    super(`Koios tx_info request failed (${status} ${statusText}).`);
    this.name = "KoiosServiceDownError";
  }
}

export async function awaitTxConfirmation(args: {
  lucid: AwaitTxLike;
  txHash: string;
  reportProgress?: (message: string) => void;
  label?: string;
  koiosApiUrl?: string;
  blockfrostApiUrl?: string;
  blockfrostProjectId?: string;
  fetchImpl?: FetchLike;
  koiosMaxAttempts?: number;
  koiosDelayMs?: number;
  primaryTimeoutMs?: number;
  blockfrostRetryAttempts?: number;
  blockfrostRetryDelayMs?: number;
}): Promise<boolean> {
  const reportProgress = args.reportProgress ?? (() => undefined);
  const primaryTimeoutMs = args.primaryTimeoutMs ?? 120_000;
  const label = args.label ?? "transaction";

  try {
    const confirmed = await Promise.race([
      args.lucid.awaitTx(args.txHash, 3_000),
      sleep(primaryTimeoutMs).then(() => false),
    ]);
    if (confirmed) {
      reportProgress(`Confirmed by Blockfrost: ${label} ${args.txHash}.`);
      return true;
    }

    reportProgress(
      `Blockfrost did not see ${args.txHash} within ${primaryTimeoutMs}ms; trying Koios.`,
    );
  } catch (error) {
    reportProgress(
      `Blockfrost lookup failed for ${args.txHash}; trying Koios (${describeError(error)}).`,
    );
  }

  const config = getCliConfig();
  const koiosApiUrl = args.koiosApiUrl ?? config.koiosApiUrl;
  const fetchImpl = args.fetchImpl ?? fetch;
  const maxAttempts = args.koiosMaxAttempts ?? 40;
  const delayMs = args.koiosDelayMs ?? 3_000;
  let lastError: unknown = null;
  let koiosDownCount = 0;

  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    try {
      const txInfo = await fetchKoiosTxInfo({
        koiosApiUrl,
        txHash: args.txHash,
        fetchImpl,
      });

      if (txInfo) {
        const location = txInfo.block_height
          ? ` at block ${txInfo.block_height}`
          : "";
        reportProgress(`Confirmed by Koios: ${label} ${args.txHash}${location}.`);
        return true;
      }
    } catch (error) {
      lastError = error;
      if (error instanceof KoiosServiceDownError && error.status >= 500) {
        koiosDownCount += 1;
        reportProgress(
          `Koios attempt ${attempt + 1}/${maxAttempts} failed for ${args.txHash} (${describeError(error)}).`,
        );
        if (koiosDownCount >= 3) {
          reportProgress(
            `Koios appears to be down (${koiosDownCount} consecutive 5xx); falling back to Blockfrost REST.`,
          );
          break;
        }
      } else {
        koiosDownCount = 0;
        reportProgress(
          `Koios attempt ${attempt + 1}/${maxAttempts} failed for ${args.txHash} (${describeError(error)}).`,
        );
      }
    }

    if (attempt + 1 < maxAttempts) {
      await sleep(delayMs);
    }
  }

  if (lastError && !(lastError instanceof KoiosServiceDownError && lastError.status >= 500)) {
    reportProgress(
      `Koios fallback exhausted for ${args.txHash}; last error: ${describeError(lastError)}.`,
    );
  }

  const blockfrostApiUrl = args.blockfrostApiUrl ?? config.blockfrostApiUrl;
  const blockfrostProjectId = args.blockfrostProjectId ?? config.blockfrostProjectId;
  const bfRetryAttempts = args.blockfrostRetryAttempts ?? 20;
  const bfRetryDelayMs = args.blockfrostRetryDelayMs ?? 6_000;

  reportProgress(
    `Retrying confirmation via Blockfrost REST for ${args.txHash} (up to ${bfRetryAttempts} attempts).`,
  );

  for (let attempt = 0; attempt < bfRetryAttempts; attempt += 1) {
    try {
      const confirmed = await fetchBlockfrostTxExists({
        blockfrostApiUrl,
        blockfrostProjectId,
        txHash: args.txHash,
        fetchImpl,
      });
      if (confirmed) {
        reportProgress(`Confirmed by Blockfrost REST: ${label} ${args.txHash}.`);
        return true;
      }
    } catch (error) {
      reportProgress(
        `Blockfrost REST attempt ${attempt + 1}/${bfRetryAttempts} failed for ${args.txHash} (${describeError(error)}).`,
      );
    }

    if (attempt + 1 < bfRetryAttempts) {
      await sleep(bfRetryDelayMs);
    }
  }

  reportProgress(`All confirmation fallbacks exhausted for ${args.txHash}.`);
  return false;
}

async function fetchKoiosTxInfo(args: {
  koiosApiUrl: string;
  txHash: string;
  fetchImpl: FetchLike;
}): Promise<KoiosTxInfo | null> {
  const response = await args.fetchImpl(`${args.koiosApiUrl}/tx_info`, {
    method: "POST",
    headers: {
      accept: "application/json",
      "content-type": "application/json",
    },
    body: JSON.stringify({ _tx_hashes: [args.txHash] }),
    signal: AbortSignal.timeout(20_000),
  });

  if (!response.ok) {
    if (response.status >= 500) {
      throw new KoiosServiceDownError(response.status, response.statusText);
    }
    throw new Error(
      `Koios tx_info request failed (${response.status} ${response.statusText}).`,
    );
  }

  const payload = (await response.json()) as KoiosTxInfo[];
  return payload[0] ?? null;
}

async function fetchBlockfrostTxExists(args: {
  blockfrostApiUrl: string;
  blockfrostProjectId: string;
  txHash: string;
  fetchImpl: FetchLike;
}): Promise<boolean> {
  const response = await args.fetchImpl(
    `${args.blockfrostApiUrl}/txs/${args.txHash}`,
    {
      headers: { project_id: args.blockfrostProjectId },
      signal: AbortSignal.timeout(20_000),
    },
  );

  if (response.status === 404) return false;

  if (!response.ok) {
    throw new Error(
      `Blockfrost REST tx lookup failed (${response.status} ${response.statusText}).`,
    );
  }

  return true;
}

function describeError(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function sleep(delayMs: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, delayMs));
}
