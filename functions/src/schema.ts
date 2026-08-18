import { z } from "zod";
import {
  MAX_PHONE_DIGITS,
  MIN_DESCRIPTION_LENGTH,
  MIN_PHONE_DIGITS,
} from "./config.js";

/**
 * The wire contract for a report, and the server's own copy of every rule the
 * wizard enforces.
 *
 * None of this trusts the client. The Flutter validation exists so the user
 * gets told what is missing while they fill the form; it is not a guarantee,
 * because anyone can call the endpoint directly.
 *
 * The enum members are the Dart enum member names, verbatim
 * (`lib/models/report_enums.dart`). They are stable identifiers, never
 * displayed — the labels live in the ARB files — so translating a label cannot
 * change what is stored.
 */

export const WHO_FOR = ["self", "someoneElse"] as const;
export const AGE_GROUP = ["child", "teen", "adult", "undisclosed"] as const;
export const GENDER = ["female", "male", "undisclosed"] as const;
export const INCIDENT_TYPE = [
  "hateSpeech",
  "discrimination",
  "defamation",
  "identityTheft",
  "intimateImages",
  "threat",
  "other",
] as const;
export const PLATFORM = [
  "whatsapp",
  "instagram",
  "tiktok",
  "facebook",
  "onlineGame",
  "messenger",
] as const;
export const ASSISTANCE_NEED = ["wanted", "none", "unsure"] as const;
export const ASSISTANCE_TYPE = [
  "legal",
  "psychological",
  "both",
  "unsure",
] as const;
export const URGENCY_LEVEL = ["urgent", "notUrgent", "unsure"] as const;

/**
 * Object paths handed out by `requestEvidenceUploadUrl` (step 4 of the plan).
 *
 * Validated for shape here so nothing else can be slipped into the field. Once
 * the upload endpoint exists, this also has to check that the path was issued
 * for *this* submission — a shape that looks right is not proof the caller was
 * ever given it.
 */
const evidencePath = z
  .string()
  .regex(
    /^evidence\/[A-Za-z0-9_-]{8,128}\/[A-Za-z0-9_-]{1,64}\.(jpg|jpeg|png|webp)$/,
    "not a path issued by requestEvidenceUploadUrl",
  );

/**
 * Free text the user wrote. Capped well above anything a person types so a
 * single request cannot be used to push megabytes into the database.
 */
const userText = (max: number) => z.string().trim().max(max);

const phoneDigits = z
  .string()
  .trim()
  .refine((value) => {
    const digits = value.replace(/\D/g, "");
    return (
      digits.length >= MIN_PHONE_DIGITS && digits.length <= MAX_PHONE_DIGITS
    );
  }, "not a plausible phone number");

const reportShape = z.object({
  whoFor: z.enum(WHO_FOR),
  ageGroup: z.enum(AGE_GROUP),
  gender: z.enum(GENDER),
  incidentType: z.enum(INCIDENT_TYPE),
  platform: z.enum(PLATFORM),
  urgencyLevel: z.enum(URGENCY_LEVEL),
  assistanceNeeded: z.enum(ASSISTANCE_NEED),

  evidencePaths: z.array(evidencePath).max(10).default([]),
  evidenceUrl: userText(2048).optional(),
  description: userText(20000).optional(),

  // Only meaningful when assistance was asked for. `normaliseReport` drops them
  // otherwise — see there.
  assistanceType: z.enum(ASSISTANCE_TYPE).optional(),
  pseudo: userText(80).optional(),
  contactPhone: phoneDigits.optional(),
});

export type ReportInput = z.infer<typeof reportShape>;

export const submitReportRequest = z.object({
  /**
   * Generated once per report by the client and reused by every retry, so a
   * send that times out after the server committed cannot open a second case.
   * See `ReportProvider._newIdempotencyKey`.
   */
  idempotencyKey: z
    .string()
    .trim()
    .min(16)
    .max(128)
    .regex(/^[A-Za-z0-9_-]+$/, "unexpected characters"),
  report: reportShape,
});

export type SubmitReportRequest = z.infer<typeof submitReportRequest>;

const isBlank = (value?: string) => !value || value.trim().length === 0;

/**
 * The rules the shape above cannot express, because they relate fields to each
 * other. Mirrors `ReportProvider.isReportComplete`.
 *
 * Returns the reasons it refuses, so the caller can log a count without logging
 * the report.
 */
export function completenessErrors(report: ReportInput): string[] {
  const errors: string[] = [];

  // A report has to carry something the team can look at: a screenshot, a link,
  // or — when the user could keep none of it — an account long enough to be
  // worth reading. The last case matters most: the worst incidents are often
  // the ones where the abuser deleted the evidence.
  const hasEvidence =
    report.evidencePaths.length > 0 || !isBlank(report.evidenceUrl);
  if (!hasEvidence) {
    const written = report.description?.trim().length ?? 0;
    if (written < MIN_DESCRIPTION_LENGTH) {
      errors.push("evidence_or_description_required");
    }
  }

  if (report.assistanceNeeded === "wanted") {
    if (!report.assistanceType) errors.push("assistance_type_required");
    if (isBlank(report.pseudo)) errors.push("pseudo_required");
    if (isBlank(report.contactPhone)) errors.push("contact_phone_required");
  }

  return errors;
}

/**
 * What actually gets stored.
 *
 * Contact details survive only when assistance was explicitly requested.
 * "I don't know" is not a request to be called back, so the client never asks
 * for a pseudonym or a number in that case — but a buggy build, an old version
 * or a crafted request could still send them, and attaching contact details to
 * a report the user believes is anonymous is the one mistake here that cannot
 * be walked back. The server drops them rather than trusting that the client
 * did.
 */
export function normaliseReport(report: ReportInput): ReportInput {
  const wantsAssistance = report.assistanceNeeded === "wanted";
  const cleaned: ReportInput = {
    ...report,
    evidenceUrl: isBlank(report.evidenceUrl) ? undefined : report.evidenceUrl,
    description: isBlank(report.description) ? undefined : report.description,
    assistanceType: wantsAssistance ? report.assistanceType : undefined,
    pseudo: wantsAssistance && !isBlank(report.pseudo) ? report.pseudo : undefined,
    contactPhone:
      wantsAssistance && !isBlank(report.contactPhone)
        ? report.contactPhone
        : undefined,
  };

  // Firestore rejects `undefined` values; an absent field is the point anyway.
  return Object.fromEntries(
    Object.entries(cleaned).filter(([, value]) => value !== undefined),
  ) as ReportInput;
}
