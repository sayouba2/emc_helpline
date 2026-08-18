import { createHash, randomBytes } from "node:crypto";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { z } from "zod";

import {
  ALLOWED_EVIDENCE_TYPES,
  EVIDENCE_PREFIX,
  MAX_EVIDENCE_BYTES,
  MAX_EVIDENCE_FILES,
  RATE_LIMITS,
  REGION,
  UPLOAD_URL_TTL_MINUTES,
} from "./config.js";
import { logProblem } from "./logging.js";
import { consumeRateLimit } from "./rateLimit.js";

/**
 * Taken from the SDK rather than imported from `@google-cloud/storage`, which
 * ships both a CJS and an ESM build with structurally incompatible types.
 */
type Bucket = ReturnType<ReturnType<typeof getStorage>["bucket"]>;

/**
 * Which folder a submission's evidence belongs in.
 *
 * Derived from the idempotency key rather than stored, so `submitReport` can
 * recompute the only folder it will accept instead of trusting the paths it is
 * handed. A caller cannot attach someone else's evidence to their own report
 * without also knowing that submission's key.
 *
 * Hashed rather than used directly: the key is the client's own value and has
 * no guaranteed shape, and a bucket path is not the place to echo it back.
 */
export function evidenceFolderFor(idempotencyKey: string): string {
  return createHash("sha256")
    .update(idempotencyKey, "utf8")
    .digest("hex")
    .slice(0, 32);
}

const EXTENSIONS: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
};

/** An object name nobody can guess, inside the submission's folder. */
export function newEvidencePath(
  idempotencyKey: string,
  contentType: string,
): string {
  const extension = EXTENSIONS[contentType];
  if (!extension) throw new HttpsError("invalid-argument", "unsupported type");
  const name = randomBytes(16).toString("hex");
  return `${EVIDENCE_PREFIX}/${evidenceFolderFor(idempotencyKey)}/${name}.${extension}`;
}

export const uploadUrlRequest = z.object({
  idempotencyKey: z
    .string()
    .trim()
    .min(16)
    .max(128)
    .regex(/^[A-Za-z0-9_-]+$/),
  contentType: z.enum(ALLOWED_EVIDENCE_TYPES),
  sizeBytes: z.number().int().positive().max(MAX_EVIDENCE_BYTES),
});

/**
 * Why a set of evidence paths cannot be accepted, or an empty list.
 *
 * Called by `submitReport` before it writes anything. Three things are checked,
 * and the first is the one that matters: **the path has to sit in the folder
 * this submission's key derives to.** A well-formed path is not proof it was
 * ever issued, and without this check a caller could reference an object
 * belonging to someone else's report.
 *
 * The other two — the object exists, and its metadata is what was promised —
 * close the gap between what a signed URL binds at issue time and what actually
 * landed in the bucket.
 */
export async function verifyEvidence(
  idempotencyKey: string,
  paths: string[],
  bucket: Bucket,
): Promise<string[]> {
  if (paths.length === 0) return [];
  if (paths.length > MAX_EVIDENCE_FILES) return ["too_many_files"];

  const expected = `${EVIDENCE_PREFIX}/${evidenceFolderFor(idempotencyKey)}/`;
  const problems: string[] = [];

  await Promise.all(
    paths.map(async (path, index) => {
      if (!path.startsWith(expected)) {
        problems.push(`path_${index}_not_issued_for_this_submission`);
        return;
      }

      const file = bucket.file(path);
      const [exists] = await file.exists();
      if (!exists) {
        problems.push(`path_${index}_missing`);
        return;
      }

      const [metadata] = await file.getMetadata();
      const size = Number(metadata.size ?? 0);
      if (size > MAX_EVIDENCE_BYTES) problems.push(`path_${index}_too_large`);

      const type = metadata.contentType ?? "";
      if (!ALLOWED_EVIDENCE_TYPES.includes(type as never)) {
        // A signed URL binds the Content-Type the client declared, but what
        // ends up in the bucket is worth re-reading rather than assumed.
        problems.push(`path_${index}_wrong_type`);
      }
    }),
  );

  return problems;
}

/**
 * Hands out one signed URL for one object.
 *
 * The bucket stays closed to clients — `storage.rules` denies everything — and
 * a signed URL carries its own authorisation, scoped to a single object, a
 * single content type and a few minutes. Nothing reaches the bucket that this
 * function did not authorise.
 */
export const requestEvidenceUploadUrl = onCall(
  { region: REGION, enforceAppCheck: true, memory: "256MiB", timeoutSeconds: 30 },
  async (request): Promise<{ uploadUrl: string; storagePath: string }> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "anonymous sign-in required");
    }

    const parsed = uploadUrlRequest.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError("invalid-argument", "malformed upload request");
    }

    const verdict = await consumeRateLimit(
      getFirestore(),
      "upload_hourly",
      uid,
      RATE_LIMITS.uploadUrlHourly,
    );
    if (!verdict.allowed) {
      logProblem({ event: "upload_rate_limited" });
      throw new HttpsError("resource-exhausted", "too many uploads");
    }

    const { idempotencyKey, contentType } = parsed.data;
    const storagePath = newEvidencePath(idempotencyKey, contentType);

    const [uploadUrl] = await getStorage()
      .bucket()
      .file(storagePath)
      .getSignedUrl({
        version: "v4",
        action: "write",
        expires: Date.now() + UPLOAD_URL_TTL_MINUTES * 60 * 1000,
        // Signed into the URL: an upload declaring anything else is refused by
        // Cloud Storage before a byte is written.
        contentType,
      });

    return { uploadUrl, storagePath };
  },
);
