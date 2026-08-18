import { createHash, randomBytes } from "node:crypto";

/**
 * The number handed to the user at the end of a report.
 *
 * This is a port of `lib/core/utils/reference_code.dart` and the two must stay
 * identical: the client parses what this generates, and both normalise what the
 * user types before comparing. The Dart file carries the full reasoning; the
 * short version is that without accounts this code is a bearer token, so it has
 * to be unguessable, and it also has to survive being read out loud over the
 * phone.
 */

/** Crockford base32: digits and letters minus `I`, `L`, `O` and `U`. */
export const ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";

export const PREFIX = "EMC";

/** 12 characters of 5 bits — 60 bits, about 10^18. */
export const PAYLOAD_LENGTH = 12;

const GROUP_SIZE = 4;

/** What a mistyped character most likely meant. */
const ALIASES: Record<string, string> = { O: "0", I: "1", L: "1" };

/**
 * A fresh code in canonical form, e.g. `EMC-4K7P-W9XM-2QTR`.
 *
 * `randomBytes`, never `Math.random`: the codes must not be predictable from
 * one another. The alphabet is exactly 32 characters, so masking a byte with
 * 31 is uniform — no modulo bias to worry about.
 */
export function generateReferenceCode(): string {
  const bytes = randomBytes(PAYLOAD_LENGTH);
  let payload = "";
  for (const byte of bytes) payload += ALPHABET[byte & 31];
  return formatReferenceCode(payload);
}

/** Canonical display form: the prefix, then groups of four. */
export function formatReferenceCode(payload: string): string {
  const groups: string[] = [];
  for (let i = 0; i < payload.length; i += GROUP_SIZE) {
    groups.push(payload.slice(i, i + GROUP_SIZE));
  }
  return `${PREFIX}-${groups.join("-")}`;
}

/**
 * The 12 significant characters of `input`, or `null` when it cannot be a
 * reference code.
 *
 * Accepts what a user actually types: lower case, missing or extra dashes,
 * spaces, with or without the prefix, and `O` for `0` or `I`/`l` for `1`.
 * Comparing two codes means comparing their payloads — never the strings.
 */
export function referencePayloadOf(input: unknown): string | null {
  if (typeof input !== "string") return null;

  let payload = "";
  for (const char of input.toUpperCase()) {
    const resolved = ALIASES[char] ?? char;
    // Anything else — dashes, spaces, punctuation — is decoration.
    if (ALPHABET.includes(resolved)) payload += resolved;
  }

  // `EMC` is itself made of alphabet characters, so it survives the strip
  // above. Length tells the two cases apart without ambiguity: a bare payload
  // is 12 characters, a prefixed one is 15.
  if (
    payload.length === PREFIX.length + PAYLOAD_LENGTH &&
    payload.startsWith(PREFIX)
  ) {
    payload = payload.slice(PREFIX.length);
  }

  return payload.length === PAYLOAD_LENGTH ? payload : null;
}

/**
 * The lookup key stored in `referenceIndex`.
 *
 * The reference code is never stored in clear, anywhere. It opens the case, so
 * a leak of the database — or a console access granted a little too widely —
 * would otherwise hand over every case at once. The consequence is accepted and
 * already stated in the app: a lost code is a lost case.
 *
 * No salt: the value hashed is 60 random bits, so there is no dictionary to
 * defend against, and a per-record salt would make lookup by code impossible,
 * which is the entire point.
 */
export function referenceHash(payload: string): string {
  return createHash("sha256").update(payload, "utf8").digest("hex");
}
