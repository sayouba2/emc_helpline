import {
  FieldValue,
  getFirestore,
  Timestamp,
  type Firestore,
} from "firebase-admin/firestore";
import { HttpsError, onCall, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";

import {
  AGENT_ROLE,
  COLLECTIONS,
  REGION,
  REPORT_RETENTION_DAYS,
  REPORT_STATUSES,
} from "./config.js";
import { logEvent } from "./logging.js";
import { referenceHash, referencePayloadOf } from "./referenceCode.js";
import { notifyStatusChange } from "./notifications.js";
import { forgetReferenceFor } from "./retention.js";

/**
 * The console is the one place with accounts.
 *
 * Agents are real people with real identities, so the anonymity that shapes the
 * rest of this backend does not apply to them — it is inverted. Every action is
 * attributed and written to `auditLog`, because the people reading children's
 * abuse reports should be the ones whose access is on the record.
 *
 * The role is a custom claim, set out of band by `scripts/grant-agent.ts`. It
 * cannot be granted from the console itself: an account that can promote
 * accounts is an account worth stealing.
 */
function requireAgent(request: CallableRequest): { uid: string; email: string } {
  const uid = request.auth?.uid;
  const token = request.auth?.token;
  if (!uid || token?.role !== AGENT_ROLE) {
    throw new HttpsError("permission-denied", "agents only");
  }
  // Sign-in providers can hand back an unverified address; a console account is
  // created deliberately, so this should never fail — which is why it is worth
  // checking.
  if (token.email_verified !== true || typeof token.email !== "string") {
    throw new HttpsError("permission-denied", "verified email required");
  }
  return { uid, email: token.email };
}

async function audit(
  db: Firestore,
  entry: {
    action: string;
    reportId: string;
    agentUid: string;
    agentEmail: string;
    from?: string;
    to?: string;
  },
): Promise<void> {
  // Outlives the case on purpose: it carries no report content, and "who looked
  // at what" is precisely the record that must survive the thing it describes.
  await db.collection(COLLECTIONS.auditLog).add({
    ...entry,
    at: FieldValue.serverTimestamp(),
  });
}

/**
 * `nullish`, pas `optional`.
 *
 * Le SDK web sérialise `undefined` en `null` : un filtre vide part donc en
 * `{status: null}`, et un schéma qui n'accepte que l'absence rejette la requête
 * la plus banale qui soit — celle de la page au premier chargement.
 */
const listRequest = z.object({
  status: z.enum(REPORT_STATUSES).nullish(),
  limit: z.number().int().min(1).max(50).nullish(),
  startAfter: z.string().min(1).nullish(),
});

/**
 * The queue: enough to triage, not enough to read.
 *
 * Deliberately withholds the description, the screenshots and the contact
 * details. Opening a case is a separate, audited act — so that scrolling a list
 * is not the same as reading twenty children's accounts.
 */
export const listReports = onCall(
  { region: REGION, memory: "256MiB", timeoutSeconds: 30 },
  async (request) => {
    requireAgent(request);
    const parsed = listRequest.safeParse(request.data ?? {});
    if (!parsed.success) {
      throw new HttpsError("invalid-argument", "malformed query");
    }

    const db = getFirestore();
    const limit = parsed.data.limit ?? 25;

    let query = db
      .collection(COLLECTIONS.reports)
      .orderBy("createdAt", "desc")
      .limit(limit);
    if (parsed.data.status) {
      query = db
        .collection(COLLECTIONS.reports)
        .where("status", "==", parsed.data.status)
        .orderBy("createdAt", "desc")
        .limit(limit);
    }
    if (parsed.data.startAfter) {
      const cursor = await db
        .collection(COLLECTIONS.reports)
        .doc(parsed.data.startAfter)
        .get();
      if (cursor.exists) query = query.startAfter(cursor);
    }

    const snapshot = await query.get();
    return {
      reports: snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          status: data.status,
          createdAt: data.createdAt?.toDate().toISOString() ?? null,
          expiresAt: data.expiresAt?.toDate().toISOString() ?? null,
          incidentType: data.incidentType,
          urgencyLevel: data.urgencyLevel,
          ageGroup: data.ageGroup,
          platform: data.platform,
          assistanceNeeded: data.assistanceNeeded,
          evidenceCount: (data.evidencePaths ?? []).length,
        };
      }),
      cursor: snapshot.docs.at(-1)?.id ?? null,
    };
  },
);

/**
 * A case is opened either from the queue, or from the number its author reads
 * out on the phone.
 *
 * The second path has to exist: the reference code is the only thing the person
 * has, and it is stored hashed, so an agent cannot search for it by eye. Without
 * this, someone calling to ask where their case stands could not be helped —
 * which is the moment the whole product is for.
 */
const getRequest = z.object({
  reportId: z.string().min(1).max(64).nullish(),
  referenceCode: z.string().min(1).max(64).nullish(),
});

/** The full case, and a line in the audit log saying who opened it. */
export const getReport = onCall(
  { region: REGION, memory: "256MiB", timeoutSeconds: 30 },
  async (request) => {
    const agent = requireAgent(request);
    const parsed = getRequest.safeParse(request.data);
    if (!parsed.success) throw new HttpsError("invalid-argument", "malformed");

    const db = getFirestore();

    let reportId = parsed.data.reportId ?? null;
    let via = "queue";

    if (!reportId) {
      // `invalid-argument` seulement quand l'appel ne dit pas quel dossier
      // ouvrir. Un numéro bien formé mais inconnu est un `not-found` : c'est
      // une faute de recopie, pas une requête malformée, et l'agent doit lire
      // « aucun dossier ne porte ce numéro », pas « requête invalide ».
      if (!parsed.data.referenceCode) {
        throw new HttpsError("invalid-argument", "malformed");
      }
      via = "reference";
      const payload = referencePayloadOf(parsed.data.referenceCode);
      if (payload) {
        const index = await db
          .collection(COLLECTIONS.referenceIndex)
          .doc(referenceHash(payload))
          .get();
        reportId = (index.data()?.reportId as string | undefined) ?? null;
      }
      if (!reportId) throw new HttpsError("not-found", "no such case");
    }

    const doc = await db.collection(COLLECTIONS.reports).doc(reportId).get();
    if (!doc.exists) throw new HttpsError("not-found", "no such case");

    await audit(db, {
      action: "read",
      reportId: doc.id,
      agentUid: agent.uid,
      agentEmail: agent.email,
      // Worth keeping apart: an agent who opened a case because its author
      // phoned is a different event from one working down the queue.
      from: via,
    });

    const data = doc.data()!;
    const evidencePaths = (data.evidencePaths ?? []) as string[];
    const bucket = (await import("firebase-admin/storage")).getStorage().bucket();

    // Short-lived read URLs rather than a public bucket: the console shows the
    // screenshots, it does not publish them.
    const evidenceUrls = await Promise.all(
      evidencePaths.map(async (path) => {
        const [url] = await bucket.file(path).getSignedUrl({
          version: "v4",
          action: "read",
          expires: Date.now() + 15 * 60 * 1000,
        });
        return url;
      }),
    );

    return {
      id: doc.id,
      ...data,
      createdAt: data.createdAt?.toDate().toISOString() ?? null,
      expiresAt: data.expiresAt?.toDate().toISOString() ?? null,
      evidencePaths: undefined,
      evidenceUrls,
    };
  },
);

const statusRequest = z.object({
  reportId: z.string().min(1).max(64),
  status: z.enum(REPORT_STATUSES),
});

/**
 * Moves a case along, and pushes its expiry out.
 *
 * The expiry refresh is the point that is easy to miss: without it, a case
 * being actively worked on would still vanish thirty days after it was filed.
 */
export const setReportStatus = onCall(
  { region: REGION, memory: "256MiB", timeoutSeconds: 30 },
  async (request) => {
    const agent = requireAgent(request);
    const parsed = statusRequest.safeParse(request.data);
    if (!parsed.success) throw new HttpsError("invalid-argument", "malformed");

    const db = getFirestore();
    const ref = db.collection(COLLECTIONS.reports).doc(parsed.data.reportId);
    const before = await ref.get();
    if (!before.exists) throw new HttpsError("not-found", "no such case");

    const from = before.data()?.status as string;
    if (from === parsed.data.status) return { status: from, changed: false };

    await ref.update({
      status: parsed.data.status,
      expiresAt: Timestamp.fromMillis(
        Date.now() + REPORT_RETENTION_DAYS * 24 * 60 * 60 * 1000,
      ),
      lastActionAt: FieldValue.serverTimestamp(),
    });

    await audit(db, {
      action: "status",
      reportId: ref.id,
      agentUid: agent.uid,
      agentEmail: agent.email,
      from,
      to: parsed.data.status,
    });

    await notifyStatusChange(db, ref.id);

    logEvent({ event: "console_status_changed", reportId: ref.id });
    return { status: parsed.data.status, changed: true };
  },
);

const deleteRequest = z.object({
  reportId: z.string().min(1).max(64),
  reason: z.string().trim().min(3).max(200),
});

/**
 * Removes a case before its time — a duplicate, or something filed by mistake.
 *
 * The evidence goes with it through `onReportDeleted`, and the audit line stays
 * behind. Someone has to be able to delete on request; nobody should be able to
 * do it without leaving a trace.
 */
export const deleteReport = onCall(
  { region: REGION, memory: "256MiB", timeoutSeconds: 60 },
  async (request) => {
    const agent = requireAgent(request);
    const parsed = deleteRequest.safeParse(request.data);
    if (!parsed.success) throw new HttpsError("invalid-argument", "malformed");

    const db = getFirestore();
    await audit(db, {
      action: "delete",
      reportId: parsed.data.reportId,
      agentUid: agent.uid,
      agentEmail: agent.email,
      to: parsed.data.reason,
    });

    await forgetReferenceFor(db, parsed.data.reportId);
    await db.collection(COLLECTIONS.reports).doc(parsed.data.reportId).delete();

    return { deleted: true };
  },
);
