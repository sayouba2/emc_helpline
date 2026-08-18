/**
 * Values that have to agree with something outside this file — the Flutter
 * client, a Firestore TTL policy, or a decision someone made on purpose.
 */

/** Closest Firestore region to Morocco. Latency, not compliance. */
export const REGION = "europe-west1";

/**
 * How much someone has to write when they attach no screenshot and no link.
 *
 * Must match `Validators.minDescriptionLength` in
 * `lib/core/utils/validators.dart`. If the two drift, the client lets a report
 * through that the server then rejects, and the user sees a failure they
 * cannot fix.
 */
export const MIN_DESCRIPTION_LENGTH = 120;

/** Permissive on purpose — foreign numbers exist. Mirrors `Validators.phone`. */
export const MIN_PHONE_DIGITS = 9;
export const MAX_PHONE_DIGITS = 15;

/**
 * How long a retry can still be recognised as the same submission.
 *
 * Past this, the same idempotency key opens a new case. Thirty days is far
 * beyond any plausible retry — the client only keeps a key while the report is
 * unsent — and keeps the collection from growing forever.
 */
export const IDEMPOTENCY_TTL_DAYS = 30;

/** Rate limits, per anonymous device UID. See docs/backend-plan.md §5. */
export const RATE_LIMITS = {
  submitReportHourly: { limit: 5, windowSeconds: 60 * 60 },
  submitReportDaily: { limit: 20, windowSeconds: 24 * 60 * 60 },
} as const;

export const COLLECTIONS = {
  reports: "reports",
  idempotency: "idempotency",
  /** Doc id is the SHA-256 of the reference payload — see referenceCode.ts. */
  referenceIndex: "referenceIndex",
  rateLimits: "rateLimits",
} as const;

/** Every state a case can be in. `trackReport` returns one of these verbatim. */
export const REPORT_STATUSES = [
  "received",
  "in_review",
  "contacted",
  "closed",
] as const;

export type ReportStatus = (typeof REPORT_STATUSES)[number];
