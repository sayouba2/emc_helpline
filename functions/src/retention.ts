import type { Firestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { onDocumentDeleted } from "firebase-functions/v2/firestore";

import { COLLECTIONS, EVIDENCE_PREFIX, REGION } from "./config.js";
import { logEvent, logProblem } from "./logging.js";

/**
 * Deletes a case's screenshots when the case itself expires.
 *
 * A Firestore TTL policy removes documents. It knows nothing about Cloud
 * Storage, so without this the retention policy would delete the report and
 * leave the evidence — photographs of children's abuse — in the bucket
 * forever, detached from the record that explained why they were there. The
 * quiet version of that failure is the dangerous one: everything looks
 * compliant from Firestore.
 */
export const onReportDeleted = onDocumentDeleted(
  { document: `${COLLECTIONS.reports}/{reportId}`, region: REGION },
  async (event) => {
    const paths = (event.data?.data()?.evidencePaths ?? []) as string[];
    if (paths.length === 0) return;

    const bucket = getStorage().bucket();
    let deleted = 0;

    await Promise.all(
      paths.map(async (path) => {
        // Belt and braces: a report should never carry a path outside the
        // evidence prefix, and this function is not the place to find out.
        if (!path.startsWith(`${EVIDENCE_PREFIX}/`)) {
          logProblem({ event: "retention_unexpected_path" });
          return;
        }
        try {
          await bucket.file(path).delete({ ignoreNotFound: true });
          deleted++;
        } catch (error) {
          // Logged, not thrown: one stubborn object must not stop the others.
          logProblem({
            event: "retention_delete_failed",
            code: (error as { code?: string }).code,
          });
        }
      }),
    );

    logEvent({ event: "retention_evidence_deleted", reportId: event.params.reportId, attempt: deleted });
  },
);

/**
 * Removes the reference index entry too, so a lookup cannot find a case that no
 * longer exists.
 *
 * The index carries its own `expiresAt`, so this is a second path to the same
 * outcome rather than the only one — TTL sweeps are not instantaneous and the
 * two documents would otherwise be out of step for hours.
 */
export async function forgetReferenceFor(
  db: Firestore,
  reportId: string,
): Promise<void> {
  const entries = await db
    .collection(COLLECTIONS.referenceIndex)
    .where("reportId", "==", reportId)
    .get();
  await Promise.all(entries.docs.map((doc) => doc.ref.delete()));
}
