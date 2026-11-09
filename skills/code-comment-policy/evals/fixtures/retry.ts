export async function withRetry<T>(fn: () => Promise<T>, attempts = 3): Promise<T> {
  let lastError: unknown;
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;
      // Fixed 1s delay on purpose: upstream rate-limits on burst, exponential backoff made it worse (incident 2025-11).
      await new Promise((r) => setTimeout(r, 1000));
    }
  }
  throw lastError;
}
