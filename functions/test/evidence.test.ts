import { deleteApp, initializeApp } from "firebase-admin/app";
import { getStorage } from "firebase-admin/storage";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

import { MAX_EVIDENCE_BYTES, MAX_EVIDENCE_FILES } from "../src/config.js";
import {
  evidenceFolderFor,
  newEvidencePath,
  verifyEvidence,
} from "../src/evidence.js";

const PROJECT_ID = "demo-emc";
const BUCKET = `${PROJECT_ID}.appspot.com`;
const emulated = Boolean(process.env.FIREBASE_STORAGE_EMULATOR_HOST);

const KEY_A = "18f2c3a4b5c6d7e8-EMC4K7PW9XM2QTR";
const KEY_B = "28f2c3a4b5c6d7e8-EMCW9XM2QTR4K7P";

describe("where evidence is allowed to live", () => {
  it("puts each submission in its own folder", () => {
    expect(evidenceFolderFor(KEY_A)).not.toBe(evidenceFolderFor(KEY_B));
    expect(evidenceFolderFor(KEY_A)).toMatch(/^[0-9a-f]{32}$/);
  });

  it("derives the folder, so it can be recomputed rather than trusted", () => {
    // This is what lets submitReport reject a path it did not issue without
    // storing anything: the same key always yields the same folder.
    expect(evidenceFolderFor(KEY_A)).toBe(evidenceFolderFor(KEY_A));
  });

  it("never echoes the idempotency key into a bucket path", () => {
    const path = newEvidencePath(KEY_A, "image/png");
    expect(path).not.toContain(KEY_A);
  });

  it("names objects unguessably, with the extension the type implies", () => {
    const names = new Set(
      Array.from({ length: 500 }, () => newEvidencePath(KEY_A, "image/jpeg")),
    );
    expect(names.size).toBe(500);
    expect(newEvidencePath(KEY_A, "image/png")).toMatch(/\.png$/);
    expect(newEvidencePath(KEY_A, "image/webp")).toMatch(/\.webp$/);
  });

  it("produces paths the report schema accepts", async () => {
    const { submitReportRequest } = await import("../src/schema.js");
    const path = newEvidencePath(KEY_A, "image/png");

    expect(() =>
      submitReportRequest.parse({
        idempotencyKey: KEY_A,
        report: {
          whoFor: "self",
          ageGroup: "teen",
          gender: "undisclosed",
          incidentType: "threat",
          platform: "whatsapp",
          urgencyLevel: "notUrgent",
          assistanceNeeded: "none",
          evidencePaths: [path],
        },
      }),
    ).not.toThrow();
  });
});

describe.skipIf(!emulated)("what submitReport will accept", () => {
  let app: ReturnType<typeof initializeApp>;

  const upload = async (
    path: string,
    bytes: number,
    contentType = "image/png",
  ) => {
    await getStorage(app)
      .bucket(BUCKET)
      .file(path)
      .save(Buffer.alloc(bytes), { contentType });
  };

  beforeAll(() => {
    app = initializeApp(
      { projectId: PROJECT_ID, storageBucket: BUCKET },
      "evidence-test",
    );
  });

  const bucket = () => getStorage(app).bucket(BUCKET);

  afterAll(async () => {
    await deleteApp(app);
  });

  it("accepts an object it issued and that actually landed", async () => {
    const path = newEvidencePath(KEY_A, "image/png");
    await upload(path, 1024);

    expect(await verifyEvidence(KEY_A, [path], bucket())).toEqual([]);
  });

  it("accepts a report with no evidence at all", async () => {
    expect(await verifyEvidence(KEY_A, [], bucket())).toEqual([]);
  });

  it("refuses another submission's evidence", async () => {
    // The check that matters. A well-formed path is not proof it was issued;
    // without this, a caller could point their report at someone else's
    // screenshots.
    const path = newEvidencePath(KEY_B, "image/png");
    await upload(path, 1024);

    expect(await verifyEvidence(KEY_A, [path], bucket())).toEqual([
      "path_0_not_issued_for_this_submission",
    ]);
  });

  it("refuses a path that points at nothing", async () => {
    const path = newEvidencePath(KEY_A, "image/png");

    expect(await verifyEvidence(KEY_A, [path], bucket())).toEqual([
      "path_0_missing",
    ]);
  });

  it("refuses an object larger than the limit", async () => {
    const path = newEvidencePath(KEY_A, "image/png");
    await upload(path, MAX_EVIDENCE_BYTES + 1);

    expect(await verifyEvidence(KEY_A, [path], bucket())).toEqual([
      "path_0_too_large",
    ]);
  });

  it("refuses an object whose stored type is not an image", async () => {
    // The signed URL binds a Content-Type at issue time; what actually landed
    // is worth re-reading rather than assumed.
    const path = newEvidencePath(KEY_A, "image/png");
    await upload(path, 1024, "application/zip");

    expect(await verifyEvidence(KEY_A, [path], bucket())).toEqual([
      "path_0_wrong_type",
    ]);
  });

  it("refuses more files than a report can carry", async () => {
    const paths = Array.from({ length: MAX_EVIDENCE_FILES + 1 }, () =>
      newEvidencePath(KEY_A, "image/png"),
    );

    expect(await verifyEvidence(KEY_A, paths, bucket())).toEqual([
      "too_many_files",
    ]);
  });

  it("reports every bad path, not just the first", async () => {
    const good = newEvidencePath(KEY_A, "image/png");
    const foreign = newEvidencePath(KEY_B, "image/png");
    const missing = newEvidencePath(KEY_A, "image/png");
    await upload(good, 1024);

    const problems = await verifyEvidence(
      KEY_A,
      [good, foreign, missing],
      bucket(),
    );

    expect(problems).toHaveLength(2);
    expect(problems).toContain("path_1_not_issued_for_this_submission");
    expect(problems).toContain("path_2_missing");
  });
});

describe("the storage emulator", () => {
  it("is what these tests run against", () => {
    expect(
      emulated,
      "run `npm run test:emulator` — FIREBASE_STORAGE_EMULATOR_HOST is not set, so the bucket tests were skipped",
    ).toBe(true);
  });
});
