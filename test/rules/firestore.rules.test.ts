import {
  assertFails,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { readFileSync } from "node:fs";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  doc,
  getDoc,
  setDoc,
  deleteDoc,
  collection,
  getDocs,
} from "firebase/firestore";

/**
 * The whole security model, verified rather than asserted.
 *
 * The whole security model rests on one claim — the client cannot touch
 * Firestore — and a rules file is easy to loosen by accident while debugging.
 * These tests fail the moment it is.
 */
const emulated = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

describe.skipIf(!emulated)("the client cannot reach Firestore", () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    const [host, port] = process.env.FIRESTORE_EMULATOR_HOST!.split(":");
    env = await initializeTestEnvironment({
      projectId: "demo-emc",
      firestore: {
        rules: readFileSync("firestore.rules", "utf8"),
        host,
        port: Number(port),
      },
    });
  });

  afterAll(async () => {
    await env?.cleanup();
  });

  // Anonymous auth exists so requests can be counted, not so they can be
  // authorised. A signed-in device must be no more privileged than a stranger.
  for (const [who, context] of [
    ["a stranger", () => env.unauthenticatedContext()],
    ["a signed-in device", () => env.authenticatedContext("anon-device-1")],
  ] as const) {
    describe(who, () => {
      it("cannot write a report", async () => {
        const db = context().firestore();
        await assertFails(
          setDoc(doc(db, "reports/forged"), { incidentType: "threat" }),
        );
      });

      it("cannot read a report", async () => {
        const db = context().firestore();
        await assertFails(getDoc(doc(db, "reports/anything")));
        await assertFails(getDocs(collection(db, "reports")));
      });

      it("cannot reach the reference index", async () => {
        // Reading it would turn a stolen backup into a working set of keys.
        const db = context().firestore();
        await assertFails(getDoc(doc(db, "referenceIndex/deadbeef")));
        await assertFails(getDocs(collection(db, "referenceIndex")));
      });

      it("cannot forge or clear an idempotency key", async () => {
        // Writing one would let an attacker suppress someone else's report;
        // deleting one would let a retry become a duplicate.
        const db = context().firestore();
        await assertFails(
          setDoc(doc(db, "idempotency/somekey"), { referenceCode: "EMC" }),
        );
        await assertFails(deleteDoc(doc(db, "idempotency/somekey")));
      });

      it("cannot erase its own rate-limit counters", async () => {
        const db = context().firestore();
        await assertFails(deleteDoc(doc(db, "rateLimits/submit_hourly_x_0")));
        await assertFails(
          setDoc(doc(db, "rateLimits/submit_hourly_x_0"), { count: 0 }),
        );
      });

      it("cannot reach a collection nobody has invented yet", async () => {
        // The rule is a catch-all, so a collection added later is closed by
        // default rather than open by oversight.
        const db = context().firestore();
        await assertFails(setDoc(doc(db, "somethingNew/x"), { a: 1 }));
        await assertFails(getDoc(doc(db, "somethingNew/x")));
      });
    });
  }
});

describe("the emulator", () => {
  it("is what these tests run against", () => {
    expect(
      emulated,
      "run `npm run test:emulator` — FIRESTORE_EMULATOR_HOST is not set, so the rules tests were skipped",
    ).toBe(true);
  });
});
