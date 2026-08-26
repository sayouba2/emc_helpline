import { deleteApp, initializeApp } from "firebase-admin/app";
import { getFirestore, type Firestore } from "firebase-admin/firestore";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";

import { COLLECTIONS } from "../src/config.js";
import { submitReportRequest } from "../src/schema.js";
import { submitReportCore } from "../src/submitReport.js";
import { trackReportCore } from "../src/trackReport.js";

const PROJECT_ID = "demo-emc";
const emulated = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

const DEVICE = "device-under-test";

const submission = (key: string, overrides: Record<string, unknown> = {}) => ({
  uid: DEVICE,
  ...submitReportRequest.parse({
    idempotencyKey: key,
    report: {
      whoFor: "self",
      ageGroup: "teen",
      gender: "undisclosed",
      incidentType: "threat",
      platform: "whatsapp",
      urgencyLevel: "urgent",
      assistanceNeeded: "wanted",
      assistanceType: "legal",
      pseudo: "HérosDiscret42",
      contactPhone: "0612345678",
      evidencePaths: [],
      description: "a".repeat(130),
      ...overrides,
    },
  }),
});

describe.skipIf(!emulated)("looking a case up by its number", () => {
  let app: ReturnType<typeof initializeApp>;
  let db: Firestore;

  beforeAll(() => {
    app = initializeApp({ projectId: PROJECT_ID }, "track-report-test");
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

  it("finds a case the user just filed", async () => {
    const filed = await submitReportCore(db, submission("key-aaaa-1111-2222"));

    const result = await trackReportCore(db, filed.referenceCode);

    expect(result.found).toBe(true);
    expect(result.report?.status).toBe("received");
    expect(result.report?.incidentType).toBe("threat");
    expect(result.report?.urgencyLevel).toBe("urgent");
    expect(Date.parse(result.report!.createdAt)).toBeGreaterThan(0);
  });

  it("gives away the status and nothing else", async () => {
    // The code is the only credential there is. One read over a shoulder, or
    // found on a shared phone, must not hand over the report itself.
    const filed = await submitReportCore(db, submission("key-bbbb-1111-2222"));

    const result = await trackReportCore(db, filed.referenceCode);

    expect(Object.keys(result.report!).sort()).toEqual([
      "createdAt",
      "incidentType",
      "status",
      "urgencyLevel",
    ]);
    const serialised = JSON.stringify(result);
    expect(serialised).not.toContain("HérosDiscret42");
    expect(serialised).not.toContain("0612345678");
    expect(serialised).not.toContain("aaaaa");
  });

  it("matches what the user typed by meaning, not by shape", async () => {
    const filed = await submitReportCore(db, submission("key-cccc-1111-2222"));
    const code = filed.referenceCode;

    for (const typed of [
      code.toLowerCase(),
      code.replace(/-/g, ""),
      `  ${code}  `,
      code.slice(4), // without the EMC prefix
      code.replace(/0/g, "O").replace(/1/g, "l"),
    ]) {
      const result = await trackReportCore(db, typed);
      expect(result.found, typed).toBe(true);
    }
  });

  it("finds nothing for a code nobody was given", async () => {
    await submitReportCore(db, submission("key-dddd-1111-2222"));

    expect((await trackReportCore(db, "EMC-0000-0000-0000")).found).toBe(false);
  });

  it("finds nothing for something that is not a code", async () => {
    for (const input of ["", "   ", "EMC", "REF-EMC-2026-123456", "hello"]) {
      expect((await trackReportCore(db, input)).found, input).toBe(false);
    }
  });

  it("tells cases apart", async () => {
    const first = await submitReportCore(db, submission("key-eeee-1111-2222"));
    const second = await submitReportCore(
      db,
      submission("key-ffff-1111-2222", { incidentType: "defamation" }),
    );

    expect((await trackReportCore(db, first.referenceCode)).report?.incidentType)
      .toBe("threat");
    expect((await trackReportCore(db, second.referenceCode)).report?.incidentType)
      .toBe("defamation");
  });

  it("survives an index entry that points at nothing", async () => {
    // submitReport writes the report and its index together, so this should be
    // impossible — which is exactly why it must not take the lookup down if it
    // ever happens.
    const filed = await submitReportCore(db, submission("key-9999-1111-2222"));
    await db.collection(COLLECTIONS.reports).doc(filed.reportId).delete();

    const result = await trackReportCore(db, filed.referenceCode);

    expect(result.found).toBe(false);
  });

  it("does not answer a retried submission with a second case", async () => {
    // The deduplicated retry returns the original code; it has to lead to the
    // original case.
    const first = await submitReportCore(db, submission("key-7777-1111-2222"));
    const retry = await submitReportCore(db, submission("key-7777-1111-2222"));

    expect(retry.referenceCode).toBe(first.referenceCode);
    expect((await trackReportCore(db, retry.referenceCode)).found).toBe(true);
    expect((await db.collection(COLLECTIONS.reports).get()).size).toBe(1);
  });
});

describe("the emulator", () => {
  it("is what these tests run against", () => {
    expect(
      emulated,
      "run `npm run test:emulator` — FIRESTORE_EMULATOR_HOST is not set, so the lookup tests were skipped",
    ).toBe(true);
  });
});
