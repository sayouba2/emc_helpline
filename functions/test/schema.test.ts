import { describe, expect, it } from "vitest";
import { MIN_DESCRIPTION_LENGTH } from "../src/config.js";
import {
  completenessErrors,
  normaliseReport,
  submitReportRequest,
  type ReportInput,
} from "../src/schema.js";

const base = {
  whoFor: "self",
  ageGroup: "teen",
  gender: "undisclosed",
  incidentType: "threat",
  platform: "whatsapp",
  urgencyLevel: "notUrgent",
  assistanceNeeded: "none",
  evidencePaths: ["evidence/abc12345/shot1.png"],
} as const;

const parse = (report: Record<string, unknown>) =>
  submitReportRequest.parse({
    idempotencyKey: "18f2c3a4b5c6d7e8-EMC4K7PW9XM2QTR",
    report,
  }).report;

describe("the wire contract", () => {
  it("accepts a well-formed report", () => {
    expect(() => parse({ ...base })).not.toThrow();
  });

  it("refuses an enum value the app cannot produce", () => {
    expect(() => parse({ ...base, incidentType: "somethingElse" })).toThrow();
    expect(() => parse({ ...base, assistanceNeeded: "WANTED" })).toThrow();
  });

  it("refuses an evidence path that was never issued", () => {
    for (const path of [
      "../../etc/passwd",
      "evidence/abc12345/shot1.exe",
      "reports/abc12345/shot1.png",
      "https://example.com/shot.png",
    ]) {
      expect(() => parse({ ...base, evidencePaths: [path] }), path).toThrow();
    }
  });

  it("caps free text so one request cannot fill the database", () => {
    expect(() => parse({ ...base, description: "x".repeat(20001) })).toThrow();
    expect(() => parse({ ...base, pseudo: "x".repeat(81) })).toThrow();
  });

  it("refuses an idempotency key that is not one", () => {
    for (const key of ["", "short", "has spaces in it here", "a".repeat(129)]) {
      expect(
        () => submitReportRequest.parse({ idempotencyKey: key, report: base }),
        key,
      ).toThrow();
    }
  });
});

describe("the rules that relate fields to each other", () => {
  it("needs something the team can look at", () => {
    const bare = parse({ ...base, evidencePaths: [] });
    expect(completenessErrors(bare)).toContain(
      "evidence_or_description_required",
    );
  });

  it("takes a long enough account in place of evidence", () => {
    // The worst incidents are often the ones where the abuser deleted
    // everything, so the story stands in for the screenshot.
    const written = parse({
      ...base,
      evidencePaths: [],
      description: "a".repeat(MIN_DESCRIPTION_LENGTH),
    });
    expect(completenessErrors(written)).toEqual([]);

    const tooShort = parse({
      ...base,
      evidencePaths: [],
      description: "a".repeat(MIN_DESCRIPTION_LENGTH - 1),
    });
    expect(completenessErrors(tooShort)).toContain(
      "evidence_or_description_required",
    );
  });

  it("demands a pseudonym and a number from whoever asked to be accompanied", () => {
    const asked = parse({ ...base, assistanceNeeded: "wanted" });
    expect(completenessErrors(asked)).toEqual([
      "assistance_type_required",
      "pseudo_required",
      "contact_phone_required",
    ]);
  });

  it("asks nothing more of a report that declined help", () => {
    for (const assistanceNeeded of ["none", "unsure"] as const) {
      expect(completenessErrors(parse({ ...base, assistanceNeeded }))).toEqual(
        [],
      );
    }
  });
});

describe("what actually gets stored", () => {
  it("drops contact details when help was not requested", () => {
    // The one mistake here that cannot be walked back: attaching a phone number
    // to a report its author believes is anonymous. An old build, a bug or a
    // crafted request must not be able to cause it.
    const crafted = parse({
      ...base,
      assistanceNeeded: "unsure",
      assistanceType: "legal",
      pseudo: "HérosDiscret42",
      contactPhone: "0612345678",
    });

    const stored = normaliseReport(crafted) as Record<string, unknown>;

    expect(stored).not.toHaveProperty("pseudo");
    expect(stored).not.toHaveProperty("contactPhone");
    expect(stored).not.toHaveProperty("assistanceType");
  });

  it("keeps them when it was", () => {
    const asked = parse({
      ...base,
      assistanceNeeded: "wanted",
      assistanceType: "legal",
      pseudo: "HérosDiscret42",
      contactPhone: "0612345678",
    });

    const stored = normaliseReport(asked);

    expect(stored.pseudo).toBe("HérosDiscret42");
    expect(stored.contactPhone).toBe("0612345678");
    expect(completenessErrors(asked)).toEqual([]);
  });

  it("leaves no undefined field for Firestore to reject", () => {
    const stored = normaliseReport(parse({ ...base }) as ReportInput);
    for (const value of Object.values(stored)) {
      expect(value).toBeDefined();
    }
  });
});
