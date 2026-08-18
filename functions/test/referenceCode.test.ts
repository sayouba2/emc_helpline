import { describe, expect, it } from "vitest";
import {
  ALPHABET,
  PAYLOAD_LENGTH,
  formatReferenceCode,
  generateReferenceCode,
  referenceHash,
  referencePayloadOf,
} from "../src/referenceCode.js";

/**
 * The Dart side has the same suite (`test/reference_code_test.dart`). Both must
 * pass, because the client parses what the server generates.
 */
describe("the code cannot be guessed", () => {
  it("carries at least 50 bits of entropy", () => {
    const bits = PAYLOAD_LENGTH * Math.log2(ALPHABET.length);

    // The old REF-EMC-2026-NNNNNN was about 20 bits — enumerable in an
    // afternoon, and these are children's cases.
    expect(bits).toBeGreaterThanOrEqual(50);
    expect(ALPHABET.length).toBe(32);
  });

  it("draws on the full alphabet, with no modulo bias", () => {
    const counts = new Map<string, number>();
    for (let i = 0; i < 4000; i++) {
      for (const char of referencePayloadOf(generateReferenceCode())!) {
        counts.set(char, (counts.get(char) ?? 0) + 1);
      }
    }

    expect(counts.size).toBe(ALPHABET.length);
    // 48000 draws over 32 symbols is 1500 each. A modulo bias would show as
    // some symbols drawn about twice as often as the rest; this band is wide
    // enough not to flake and far tighter than that.
    for (const [char, count] of counts) {
      expect(count, char).toBeGreaterThan(1500 * 0.75);
      expect(count, char).toBeLessThan(1500 * 1.25);
    }
  });

  it("does not repeat itself", () => {
    const codes = new Set(
      Array.from({ length: 5000 }, () => generateReferenceCode()),
    );
    expect(codes.size).toBe(5000);
  });
});

describe("the code can be read out loud", () => {
  it("never uses a character that reads as another", () => {
    for (const ambiguous of ["I", "L", "O", "U"]) {
      expect(ALPHABET, ambiguous).not.toContain(ambiguous);
    }
  });

  it("is grouped, prefixed and uppercase", () => {
    expect(generateReferenceCode()).toMatch(/^EMC(-[0-9A-Z]{4}){3}$/);
  });
});

describe("what the user types is matched by meaning, not by shape", () => {
  const payload = referencePayloadOf("EMC-4K7P-W9XM-2QTR");

  it("accepts the canonical form", () => {
    expect(payload).toBe("4K7PW9XM2QTR");
  });

  it("forgives case, spacing, missing dashes and the prefix", () => {
    for (const variant of [
      "emc-4k7p-w9xm-2qtr",
      "EMC4K7PW9XM2QTR",
      "  EMC 4K7P W9XM 2QTR  ",
      "4K7PW9XM2QTR",
      "4k7p-w9xm-2qtr",
    ]) {
      expect(referencePayloadOf(variant), variant).toBe(payload);
    }
  });

  it("forgives the confusions the alphabet could not remove", () => {
    expect(referencePayloadOf("EMC-O123-4567-89AB")).toBe("0123456789AB");
    expect(referencePayloadOf("EMC-I123-4567-89AB")).toBe("1123456789AB");
    expect(referencePayloadOf("EMC-l123-4567-89AB")).toBe("1123456789AB");
  });

  it("rejects what cannot be a code", () => {
    for (const invalid of ["", "   ", "EMC", "4K7P", "REF-EMC-2026-123456"]) {
      expect(referencePayloadOf(invalid), invalid).toBeNull();
    }
    expect(referencePayloadOf(null)).toBeNull();
    expect(referencePayloadOf(undefined)).toBeNull();
    expect(referencePayloadOf(42)).toBeNull();
  });

  it("does not mistake a bare payload starting with EMC for a prefix", () => {
    expect(referencePayloadOf("EMC123456789")).toBe("EMC123456789");
    expect(referencePayloadOf("EMC-EMC1-2345-6789")).toBe("EMC123456789");
  });

  it("round-trips through its own display form", () => {
    for (let i = 0; i < 200; i++) {
      const code = generateReferenceCode();
      expect(formatReferenceCode(referencePayloadOf(code)!)).toBe(code);
    }
  });
});

describe("the stored form", () => {
  it("is a hash, so the database never holds a usable code", () => {
    const code = generateReferenceCode();
    const hash = referenceHash(referencePayloadOf(code)!);

    expect(hash).toMatch(/^[0-9a-f]{64}$/);
    expect(hash).not.toContain(referencePayloadOf(code)!);
  });

  it("hashes what the user typed, not how they typed it", () => {
    const a = referenceHash(referencePayloadOf("EMC-4K7P-W9XM-2QTR")!);
    const b = referenceHash(referencePayloadOf("emc4k7pw9xm2qtr")!);

    expect(a).toBe(b);
  });
});
