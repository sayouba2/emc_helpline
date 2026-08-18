import { HttpsError, onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp, type Firestore } from "firebase-admin/firestore";

import {
  COLLECTIONS,
  IDEMPOTENCY_TTL_DAYS,
  RATE_LIMITS,
  REGION,
} from "./config.js";
import { issuePaths, logEvent, logProblem } from "./logging.js";
import {
  formatReferenceCode,
  generateReferenceCode,
  referenceHash,
  referencePayloadOf,
} from "./referenceCode.js";
import { consumeRateLimit } from "./rateLimit.js";
import {
  completenessErrors,
  normaliseReport,
  submitReportRequest,
  type ReportInput,
} from "./schema.js";

export type SubmitResult = {
  referenceCode: string;
  reportId: string;
  /** True when this exact submission had already been filed. */
  deduplicated: boolean;
};

/**
 * How many times to redraw on a reference-code collision before giving up.
 *
 * At 60 bits a collision is not something to plan a day around, but the check
 * is one read and the alternative is two people sharing a case. Five failures
 * in a row means something is wrong with the random source, and failing loudly
 * is the right answer to that.
 */
const MAX_CODE_ATTEMPTS = 5;

/**
 * Files a report, or returns the one this submission already produced.
 *
 * Split from the callable wrapper so it can be driven straight against the
 * Firestore emulator, without going through auth, App Check and the functions
 * runtime — the interesting behaviour is the transaction, and that is what the
 * tests exercise.
 */
export async function submitReportCore(
  db: Firestore,
  input: { idempotencyKey: string; report: ReportInput },
  now: Date = new Date(),
): Promise<SubmitResult> {
  const report = normaliseReport(input.report);
  const idempotencyRef = db
    .collection(COLLECTIONS.idempotency)
    .doc(input.idempotencyKey);

  return db.runTransaction(async (tx) => {
    // Everything Firestore reads has to happen before anything it writes, so
    // the whole decision is made up front.
    const existing = await tx.get(idempotencyRef);
    if (existing.exists) {
      const data = existing.data()!;
      // The retry the client makes after a timeout lands here. The report was
      // already filed; hand back the same code rather than opening a duplicate.
      return {
        referenceCode: data.referenceCode as string,
        reportId: data.reportId as string,
        deduplicated: true,
      };
    }

    let referenceCode: string | null = null;
    let hash = "";
    for (let attempt = 0; attempt < MAX_CODE_ATTEMPTS; attempt++) {
      const candidate = generateReferenceCode();
      const candidateHash = referenceHash(referencePayloadOf(candidate)!);
      const clash = await tx.get(
        db.collection(COLLECTIONS.referenceIndex).doc(candidateHash),
      );
      if (!clash.exists) {
        referenceCode = candidate;
        hash = candidateHash;
        break;
      }
      logProblem({ event: "reference_code_collision", attempt });
    }
    if (!referenceCode) {
      throw new HttpsError(
        "internal",
        "could not allocate a reference code",
      );
    }

    const reportRef = db.collection(COLLECTIONS.reports).doc();
    const createdAt = Timestamp.fromDate(now);
    const idempotencyExpiry = Timestamp.fromMillis(
      now.getTime() + IDEMPOTENCY_TTL_DAYS * 24 * 60 * 60 * 1000,
    );

    // The three writes are one transaction on purpose. A report without its
    // index entry is a case nobody can look up; an index entry without its
    // idempotency record turns the next retry into a duplicate. Either both
    // land or neither does.
    tx.set(reportRef, {
      ...report,
      status: "received",
      createdAt,
      // No `expiresAt`: the retention period is a decision for CMRPI, and a TTL
      // policy invented here would quietly start deleting evidence.
    });
    tx.set(db.collection(COLLECTIONS.referenceIndex).doc(hash), {
      reportId: reportRef.id,
      createdAt,
    });
    tx.set(idempotencyRef, {
      reportId: reportRef.id,
      referenceCode,
      createdAt,
      expiresAt: idempotencyExpiry,
    });

    return { referenceCode, reportId: reportRef.id, deduplicated: false };
  });
}

/**
 * The endpoint the app calls.
 *
 * App Check attests that the request comes from a real build of the app;
 * anonymous Auth gives a per-installation identifier used only to count
 * requests. Neither is a login — there are no accounts, deliberately.
 */
export const submitReport = onCall(
  {
    region: REGION,
    enforceAppCheck: true,
    // Evidence travels as storage paths, so the payload is small; a report is
    // a few kilobytes at most.
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  async (request): Promise<{ referenceCode: string }> => {
    const startedAt = Date.now();

    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "anonymous sign-in required");
    }

    const parsed = submitReportRequest.safeParse(request.data);
    if (!parsed.success) {
      // Field names and failure kinds only. A Zod issue carries the offending
      // value, and that value is the report.
      logProblem({
        event: "submit_rejected_shape",
        reasons: issuePaths(parsed.error.issues),
      });
      throw new HttpsError("invalid-argument", "malformed report");
    }

    const problems = completenessErrors(parsed.data.report);
    if (problems.length > 0) {
      logProblem({ event: "submit_rejected_incomplete", reasons: problems });
      throw new HttpsError("invalid-argument", "incomplete report");
    }

    const db = getFirestore();
    for (const [scope, rule] of [
      ["submit_hourly", RATE_LIMITS.submitReportHourly],
      ["submit_daily", RATE_LIMITS.submitReportDaily],
    ] as const) {
      const verdict = await consumeRateLimit(db, scope, uid, rule);
      if (!verdict.allowed) {
        logProblem({ event: "submit_rate_limited", reasons: [scope] });
        // "resource-exhausted" maps to `SubmissionFailure.server` on the
        // client, which invites a retry later. Deliberate: a child who hits
        // this is far more likely to be on a shared phone than attacking us.
        throw new HttpsError("resource-exhausted", "too many reports");
      }
    }

    const result = await submitReportCore(db, parsed.data);

    logEvent({
      event: "submit_ok",
      reportId: result.reportId,
      deduplicated: result.deduplicated,
      durationMs: Date.now() - startedAt,
    });

    return { referenceCode: result.referenceCode };
  },
);

export { formatReferenceCode };
