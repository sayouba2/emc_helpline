import { getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { z } from "zod";

import { COLLECTIONS, RATE_LIMITS, REGION } from "./config.js";
import { logEvent, logProblem } from "./logging.js";
import { consumeRateLimit } from "./rateLimit.js";
import { referenceHash, referencePayloadOf } from "./referenceCode.js";

export type TrackedReport = {
  status: string;
  createdAt: string;
  incidentType: string;
  urgencyLevel: string;
};

export type TrackResult = { found: boolean; report?: TrackedReport };

const trackRequest = z.object({
  referenceCode: z.string().trim().min(1).max(64),
});

/**
 * Looks a case up by the number handed to its author.
 *
 * There is no account to authenticate against, so the reference code is the
 * only credential — which is why it carries 60 bits and why nothing here
 * returns more than a status.
 */
export async function trackReportCore(
  db: FirebaseFirestore.Firestore,
  referenceCode: string,
): Promise<TrackResult> {
  const payload = referencePayloadOf(referenceCode);
  if (!payload) return { found: false };

  const index = await db
    .collection(COLLECTIONS.referenceIndex)
    .doc(referenceHash(payload))
    .get();
  if (!index.exists) return { found: false };

  const reportId = index.data()?.reportId as string | undefined;
  const report = reportId
    ? await db.collection(COLLECTIONS.reports).doc(reportId).get()
    : null;

  if (!report?.exists) {
    // An index entry pointing at nothing means the two writes came apart,
    // which the transaction in submitReport is supposed to make impossible.
    logProblem({ event: "track_dangling_index", reportId });
    return { found: false };
  }

  const data = report.data()!;
  // Only these four fields. Not the description, not the screenshots, not the
  // pseudonym or the phone number. A code that leaks — read over someone's
  // shoulder, found on a shared phone — gives away where the case stands, and
  // that is all it can give away.
  return {
    found: true,
    report: {
      status: data.status as string,
      createdAt: data.createdAt.toDate().toISOString(),
      incidentType: data.incidentType as string,
      urgencyLevel: data.urgencyLevel as string,
    },
  };
}

export const trackReport = onCall(
  { region: REGION, enforceAppCheck: true, memory: "256MiB", timeoutSeconds: 20 },
  async (request): Promise<TrackResult> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "anonymous sign-in required");
    }

    const parsed = trackRequest.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError("invalid-argument", "malformed lookup");
    }

    const db = getFirestore();
    const verdict = await consumeRateLimit(
      db,
      "track_hourly",
      uid,
      RATE_LIMITS.trackReportHourly,
    );
    if (!verdict.allowed) {
      // Told apart from "no such case" on purpose. Returning "not found" to
      // someone who simply checked on their case too often would read as their
      // report having vanished, and the enumeration this would obscure is not
      // the thing standing between an attacker and a case — 60 bits of entropy
      // is. See docs/backend-plan.md §5.
      logProblem({ event: "track_rate_limited" });
      throw new HttpsError("resource-exhausted", "too many lookups");
    }

    const result = await trackReportCore(db, parsed.data.referenceCode);

    // No code, no id, nothing identifying. This exists so a log-based alert can
    // watch the miss rate: a sustained run of misses is what enumeration looks
    // like, and it is the signal per-device limits cannot see.
    logEvent({ event: result.found ? "track_hit" : "track_miss" });

    return result;
  },
);
