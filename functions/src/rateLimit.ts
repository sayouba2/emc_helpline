import { FieldValue, type Firestore, Timestamp } from "firebase-admin/firestore";
import { COLLECTIONS } from "./config.js";

/**
 * A fixed-window counter, one document per (scope, subject, window).
 *
 * Keyed by the anonymous Auth UID, which identifies an installation and nothing
 * else. That UID is never written to a report: two reports from the same phone
 * must not become linkable, or the anonymity the app promises is a fiction.
 * It lives here only, on documents that expire.
 *
 * Fixed windows let through up to twice the limit across a boundary. That is
 * fine for what this defends — flooding and enumeration, not precision — and it
 * costs one document read and one write instead of the ordered set a sliding
 * window needs.
 */
export type RateLimitRule = { limit: number; windowSeconds: number };

export type RateLimitVerdict = {
  allowed: boolean;
  /** Seconds until the window resets. Never returned to the caller — see below. */
  retryAfterSeconds: number;
};

export async function consumeRateLimit(
  db: Firestore,
  scope: string,
  subject: string,
  rule: RateLimitRule,
  now: Date = new Date(),
): Promise<RateLimitVerdict> {
  const windowStart =
    Math.floor(now.getTime() / 1000 / rule.windowSeconds) * rule.windowSeconds;
  const id = `${scope}_${subject}_${windowStart}`;
  const ref = db.collection(COLLECTIONS.rateLimits).doc(id);
  const resetsAt = new Date((windowStart + rule.windowSeconds) * 1000);

  const allowed = await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    const count = (snapshot.data()?.count as number | undefined) ?? 0;
    if (count >= rule.limit) return false;

    tx.set(
      ref,
      {
        count: FieldValue.increment(1),
        scope,
        windowStart: Timestamp.fromMillis(windowStart * 1000),
        // Swept by a Firestore TTL policy on this field.
        expiresAt: Timestamp.fromDate(resetsAt),
      },
      { merge: true },
    );
    return true;
  });

  return {
    allowed,
    retryAfterSeconds: Math.max(
      0,
      Math.ceil((resetsAt.getTime() - now.getTime()) / 1000),
    ),
  };
}
