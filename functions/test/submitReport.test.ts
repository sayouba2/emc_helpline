import { cert, deleteApp, initializeApp } from "firebase-admin/app";
import { getFirestore, type Firestore } from "firebase-admin/firestore";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";

import { COLLECTIONS } from "../src/config.js";
import { referenceHash, referencePayloadOf } from "../src/referenceCode.js";
import { consumeRateLimit } from "../src/rateLimit.js";
import { submitReportCore } from "../src/submitReport.js";
import { submitReportRequest } from "../src/schema.js";

const PROJECT_ID = "demo-emc";
const emulated = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

/** Le même appareil, sauf mention contraire. */
const DEVICE = "device-under-test";

const report = (overrides: Record<string, unknown> = {}) => ({
  uid: DEVICE,
  ...submitReportRequest.parse({
    idempotencyKey: "18f2c3a4b5c6d7e8-EMC4K7PW9XM2QTR",
    report: {
      whoFor: "self",
      ageGroup: "teen",
      gender: "undisclosed",
      incidentType: "threat",
      platform: "whatsapp",
      urgencyLevel: "notUrgent",
      assistanceNeeded: "none",
      evidencePaths: ["evidence/abc12345/shot1.png"],
      ...overrides,
    },
  }),
});

describe.skipIf(!emulated)("filing a report", () => {
  let app: ReturnType<typeof initializeApp>;
  let db: Firestore;

  beforeAll(() => {
    app = initializeApp({ projectId: PROJECT_ID }, "submit-report-test");
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

  it("stores the report and hands back a code", async () => {
    const result = await submitReportCore(db, report());

    expect(result.deduplicated).toBe(false);
    expect(result.referenceCode).toMatch(/^EMC(-[0-9A-Z]{4}){3}$/);

    const stored = await db
      .collection(COLLECTIONS.reports)
      .doc(result.reportId)
      .get();
    expect(stored.exists).toBe(true);
    expect(stored.data()?.status).toBe("received");
    expect(stored.data()?.incidentType).toBe("threat");
  });

  it("never writes the reference code into the report", async () => {
    // The code opens the case. Storing it in clear means a database leak — or a
    // console access granted a little too widely — hands over every case at
    // once. Only its hash is kept, in a separate collection.
    const result = await submitReportCore(db, report());

    const stored = (
      await db.collection(COLLECTIONS.reports).doc(result.reportId).get()
    ).data()!;
    expect(JSON.stringify(stored)).not.toContain(
      referencePayloadOf(result.referenceCode),
    );

    const hash = referenceHash(referencePayloadOf(result.referenceCode)!);
    const index = await db
      .collection(COLLECTIONS.referenceIndex)
      .doc(hash)
      .get();
    expect(index.exists).toBe(true);
    expect(index.data()?.reportId).toBe(result.reportId);
  });

  it("returns the same code for a retry, and files nothing twice", async () => {
    // This is the whole point of the idempotency key: the client retries after
    // a timeout, and the server may already have committed.
    const first = await submitReportCore(db, report());
    const second = await submitReportCore(db, report());
    const third = await submitReportCore(db, report());

    expect(second.referenceCode).toBe(first.referenceCode);
    expect(third.referenceCode).toBe(first.referenceCode);
    expect(second.deduplicated).toBe(true);
    expect(third.deduplicated).toBe(true);

    const all = await db.collection(COLLECTIONS.reports).get();
    expect(all.size).toBe(1);
  });

  it("deduplicates even when two retries race", async () => {
    // A flaky connection produces exactly this: the client gives up on the
    // first attempt and fires a second while the first is still in flight.
    const results = await Promise.all([
      submitReportCore(db, report()),
      submitReportCore(db, report()),
      submitReportCore(db, report()),
    ]);

    const codes = new Set(results.map((r) => r.referenceCode));
    expect(codes.size).toBe(1);

    const all = await db.collection(COLLECTIONS.reports).get();
    expect(all.size).toBe(1);
  });

  it("ne rend pas le code d'un autre à qui rejoue sa clé", async () => {
    // Le code de référence est le seul justificatif du dossier : il ouvre le
    // suivi. La clé d'idempotence en était un second chemin, sans les mêmes
    // garanties — elle vient du client.
    const filed = await submitReportCore(db, report());

    await expect(
      submitReportCore(db, { ...report(), uid: "un-autre-appareil" }),
    ).rejects.toThrow(/permission-denied|not your submission/);

    // Et le dossier d'origine est intact.
    const all = await db.collection(COLLECTIONS.reports).get();
    expect(all.size).toBe(1);
    expect(filed.deduplicated).toBe(false);
  });

  it("gives a different report a different key and a different code", async () => {
    const first = await submitReportCore(db, report());
    const second = await submitReportCore(db, {
      ...report(),
      idempotencyKey: "28f2c3a4b5c6d7e8-EMCW9XM2QTR4K7P",
    });

    expect(second.referenceCode).not.toBe(first.referenceCode);
    expect(second.reportId).not.toBe(first.reportId);

    const all = await db.collection(COLLECTIONS.reports).get();
    expect(all.size).toBe(2);
  });

  it("writes the report, its index entry and its key together or not at all", async () => {
    const result = await submitReportCore(db, report());
    const hash = referenceHash(referencePayloadOf(result.referenceCode)!);

    const [stored, index, key] = await Promise.all([
      db.collection(COLLECTIONS.reports).doc(result.reportId).get(),
      db.collection(COLLECTIONS.referenceIndex).doc(hash).get(),
      db
        .collection(COLLECTIONS.idempotency)
        .doc(report().idempotencyKey)
        .get(),
    ]);

    // A report without its index is a case nobody can look up; an index without
    // its key turns the next retry into a duplicate.
    expect(stored.exists).toBe(true);
    expect(index.exists).toBe(true);
    expect(key.exists).toBe(true);
    expect(key.data()?.referenceCode).toBe(result.referenceCode);
    expect(key.data()?.expiresAt).toBeDefined();
  });

  it("does not attach contact details to a report that declined help", async () => {
    const result = await submitReportCore(
      db,
      report({
        assistanceNeeded: "unsure",
        pseudo: "HérosDiscret42",
        contactPhone: "0612345678",
        assistanceType: "legal",
      }),
    );

    const stored = (
      await db.collection(COLLECTIONS.reports).doc(result.reportId).get()
    ).data()!;

    expect(stored.pseudo).toBeUndefined();
    expect(stored.contactPhone).toBeUndefined();
  });
});

describe.skipIf(!emulated)("rate limiting", () => {
  let app: ReturnType<typeof initializeApp>;
  let db: Firestore;

  beforeAll(() => {
    app = initializeApp({ projectId: PROJECT_ID }, "rate-limit-test");
    db = getFirestore(app);
  });

  afterAll(async () => {
    await deleteApp(app);
  });

  it("lets the allowance through, then stops", async () => {
    const rule = { limit: 3, windowSeconds: 3600 };
    const uid = `device-${Date.now()}`;

    const verdicts = [];
    for (let i = 0; i < 5; i++) {
      verdicts.push(await consumeRateLimit(db, "test", uid, rule));
    }

    expect(verdicts.map((v) => v.allowed)).toEqual([
      true,
      true,
      true,
      false,
      false,
    ]);
  });

  it("counts each device separately", async () => {
    const rule = { limit: 1, windowSeconds: 3600 };
    const stamp = Date.now();

    expect((await consumeRateLimit(db, "test", `a-${stamp}`, rule)).allowed).toBe(true);
    expect((await consumeRateLimit(db, "test", `b-${stamp}`, rule)).allowed).toBe(true);
    expect((await consumeRateLimit(db, "test", `a-${stamp}`, rule)).allowed).toBe(false);
  });

  it("starts a fresh window when the old one has passed", async () => {
    const rule = { limit: 1, windowSeconds: 60 };
    const uid = `device-${Date.now()}`;
    const now = new Date();
    const later = new Date(now.getTime() + 61_000);

    expect((await consumeRateLimit(db, "test", uid, rule, now)).allowed).toBe(true);
    expect((await consumeRateLimit(db, "test", uid, rule, now)).allowed).toBe(false);
    expect((await consumeRateLimit(db, "test", uid, rule, later)).allowed).toBe(true);
  });

  it("sets an expiry so the counters do not pile up forever", async () => {
    const uid = `device-${Date.now()}`;
    await consumeRateLimit(db, "ttl", uid, { limit: 5, windowSeconds: 60 });

    const docs = await db
      .collection(COLLECTIONS.rateLimits)
      .where("scope", "==", "ttl")
      .get();

    expect(docs.empty).toBe(false);
    for (const doc of docs.docs) expect(doc.data().expiresAt).toBeDefined();
  });
});

// Guards against the suite silently passing because nothing ran.
describe("the emulator", () => {
  it("is what these tests run against", () => {
    expect(
      emulated,
      "run `npm run test:emulator` — FIRESTORE_EMULATOR_HOST is not set, so the Firestore tests were skipped",
    ).toBe(true);
  });
});

void cert;
