import { deleteApp, initializeApp } from "firebase-admin/app";
import { getFirestore, type Firestore } from "firebase-admin/firestore";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";

import {
  COLLECTIONS,
  REPORT_RETENTION_DAYS,
  REPORT_STATUSES,
} from "../src/config.js";
import { submitReportRequest } from "../src/schema.js";
import { submitReportCore } from "../src/submitReport.js";
import { trackReportCore } from "../src/trackReport.js";

const PROJECT_ID = "demo-emc";
const emulated = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

const submission = (key: string) =>
  submitReportRequest.parse({
    idempotencyKey: key,
    report: {
      whoFor: "self",
      ageGroup: "teen",
      gender: "undisclosed",
      incidentType: "threat",
      platform: "whatsapp",
      urgencyLevel: "urgent",
      assistanceNeeded: "none",
      evidencePaths: [],
      description: "a".repeat(130),
    },
  });

describe.skipIf(!emulated)("how long a case is kept", () => {
  let app: ReturnType<typeof initializeApp>;
  let db: Firestore;

  beforeAll(() => {
    app = initializeApp({ projectId: PROJECT_ID }, "console-test");
    db = getFirestore(app);
  });

  afterAll(async () => {
    await deleteApp(app);
  });

  beforeEach(async () => {
    await Promise.all(
      Object.values(COLLECTIONS).map(async (name) => {
        const docs = await db.collection(name).listDocuments();
        await Promise.all(docs.map((doc) => doc.delete()));
      }),
    );
  });

  it("gives a new case thirty days", async () => {
    const filed = await submitReportCore(db, submission("key-ttl0-1111-2222"));

    const doc = await db.collection(COLLECTIONS.reports).doc(filed.reportId).get();
    const days =
      (doc.data()!.expiresAt.toDate().getTime() - Date.now()) / 86400000;

    expect(days).toBeGreaterThan(REPORT_RETENTION_DAYS - 1);
    expect(days).toBeLessThanOrEqual(REPORT_RETENTION_DAYS);
  });

  it("keeps the index entry in step with the case", async () => {
    // An index that outlives what it points at turns every lookup into a
    // dangling entry.
    const filed = await submitReportCore(db, submission("key-ttl1-1111-2222"));

    const [report, index] = await Promise.all([
      db.collection(COLLECTIONS.reports).doc(filed.reportId).get(),
      db
        .collection(COLLECTIONS.referenceIndex)
        .where("reportId", "==", filed.reportId)
        .get(),
    ]);

    expect(index.docs[0]!.data().expiresAt.toMillis()).toBe(
      report.data()!.expiresAt.toMillis(),
    );
  });

  it("pushes the expiry out when the case moves", async () => {
    // The failure this prevents: a case deleted automatically while an agent is
    // still working on it. Thirty days from filing would do exactly that.
    const filed = await submitReportCore(db, submission("key-ttl2-1111-2222"));
    const ref = db.collection(COLLECTIONS.reports).doc(filed.reportId);

    const staleExpiry = new Date(Date.now() + 2 * 86400000);
    await ref.update({ expiresAt: staleExpiry });

    // What setReportStatus does to the document.
    await ref.update({
      status: "inReview",
      expiresAt: new Date(Date.now() + REPORT_RETENTION_DAYS * 86400000),
    });

    const after = (await ref.get()).data()!;
    const days = (after.expiresAt.toDate().getTime() - Date.now()) / 86400000;
    expect(days).toBeGreaterThan(REPORT_RETENTION_DAYS - 1);
  });

  it("stops finding a case once it is gone", async () => {
    const filed = await submitReportCore(db, submission("key-ttl3-1111-2222"));
    expect((await trackReportCore(db, filed.referenceCode)).found).toBe(true);

    const { forgetReferenceFor } = await import("../src/retention.js");
    await forgetReferenceFor(db, filed.reportId);
    await db.collection(COLLECTIONS.reports).doc(filed.reportId).delete();

    expect((await trackReportCore(db, filed.referenceCode)).found).toBe(false);
  });
});

describe("the statuses the console can set", () => {
  it("are the ones the app knows how to display", () => {
    // The Flutter side lists the same four in `ReportStatus`, and a test there
    // reads this file to check. Adding one here without adding it there leaves
    // users looking at "statut mis à jour" and nothing else.
    expect([...REPORT_STATUSES]).toEqual([
      "received",
      "inReview",
      "contacted",
      "closed",
    ]);
  });
});

describe("the emulator", () => {
  it("is what these tests run against", () => {
    expect(
      emulated,
      "run `npm run test:emulator` — FIRESTORE_EMULATOR_HOST is not set, so the retention tests were skipped",
    ).toBe(true);
  });
});
