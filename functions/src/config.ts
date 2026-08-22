/**
 * Values that have to agree with something outside this file — the Flutter
 * client, a Firestore TTL policy, or a decision someone made on purpose.
 */

/** Closest Firestore region to Morocco. Latency, not compliance. */
export const REGION = "europe-west1";

/**
 * Whether callables demand a valid App Check token.
 *
 * On, always, except inside the emulator suite. `enforceAppCheck` is enforced
 * by `firebase-functions` itself, in process — it is not a Google-side check
 * that the emulators simply skip. A local run therefore answers every call with
 * `401 UNAUTHENTICATED`, however good the auth token is, and no amount of
 * client-side fiddling changes that.
 *
 * The escape hatch is `FUNCTIONS_EMULATOR`, which the emulator sets and which
 * nothing in production can set: a deployed function always enforces.
 */
export const ENFORCE_APP_CHECK = process.env.FUNCTIONS_EMULATOR !== "true";

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

/**
 * How long a case is kept, counted from its last activity.
 *
 * Thirty days, as decided by CMRPI. It is a **sliding** window: filing a report
 * sets it, and every status change pushes it out again. A fixed thirty days
 * from creation would delete a case while someone was still working on it,
 * which is the one failure mode a retention policy must not have.
 *
 * A case that nobody touches for thirty days disappears — the report, its
 * screenshots, and the reference number's ability to find anything.
 */
export const REPORT_RETENTION_DAYS = 30;

/** Rate limits, per anonymous device UID. See docs/backend-plan.md §5. */
export const RATE_LIMITS = {
  submitReportHourly: { limit: 5, windowSeconds: 60 * 60 },
  submitReportDaily: { limit: 20, windowSeconds: 24 * 60 * 60 },
  uploadUrlHourly: { limit: 20, windowSeconds: 60 * 60 },
  trackReportHourly: { limit: 10, windowSeconds: 60 * 60 },
} as const;

/** Who may reach the team console. Carried as a custom claim on the account. */
export const AGENT_ROLE = "agent";

/** Evidence lives under this prefix and nowhere else. */
export const EVIDENCE_PREFIX = "evidence";

/**
 * How long a signed upload URL stays usable.
 *
 * Long enough for several screenshots over a slow mobile connection, short
 * enough that a URL captured from a log or a proxy is worthless by the time
 * anyone looks at it.
 */
export const UPLOAD_URL_TTL_MINUTES = 15;

/** Phone screenshots. Ten of them is already an unusually thorough report. */
export const MAX_EVIDENCE_FILES = 10;
export const MAX_EVIDENCE_BYTES = 8 * 1024 * 1024;

export const ALLOWED_EVIDENCE_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
] as const;

export const COLLECTIONS = {
  reports: "reports",
  idempotency: "idempotency",
  /** Doc id is the SHA-256 of the reference payload — see referenceCode.ts. */
  referenceIndex: "referenceIndex",
  rateLimits: "rateLimits",
  /** Every agent action on a case. Never deleted with the case. */
  auditLog: "auditLog",
} as const;

/** Every state a case can be in. `trackReport` returns one of these verbatim. */
export const REPORT_STATUSES = [
  "received",
  "inReview",
  "contacted",
  "closed",
] as const;

export type ReportStatus = (typeof REPORT_STATUSES)[number];
