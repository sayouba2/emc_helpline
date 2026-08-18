import { logger } from "firebase-functions";

/**
 * Logging that cannot leak a report.
 *
 * Cloud Logging is readable by anyone with project access, is retained for a
 * long time, and leaves the perimeter these records were designed for. Nothing
 * a user wrote may reach it: not the description, not the pseudonym, not the
 * phone number, not the reference code, not an evidence path.
 *
 * So logging goes through this allow-list instead of `logger.info` directly.
 * The trap it exists to close is validation errors: a Zod issue carries the
 * offending value by default, and `logger.error(error)` on a rejected report
 * would print the very fields this is meant to protect.
 */
type Loggable = {
  event: string;
  reportId?: string;
  /** Names of the checks that failed — never the values that failed them. */
  reasons?: string[];
  deduplicated?: boolean;
  durationMs?: number;
  code?: string;
  attempt?: number;
};

export function logEvent(entry: Loggable): void {
  logger.info(entry.event, safe(entry));
}

export function logProblem(entry: Loggable): void {
  logger.error(entry.event, safe(entry));
}

function safe(entry: Loggable): Record<string, unknown> {
  const { event, ...rest } = entry;
  void event;
  return Object.fromEntries(
    Object.entries(rest).filter(([, value]) => value !== undefined),
  );
}

/**
 * Field names of a Zod failure, without the values.
 *
 * `issue.path` is the field that failed and `issue.code` is the kind of
 * failure; neither contains user input. `issue.message` can, on a custom
 * refinement, so it is left out.
 */
export function issuePaths(issues: { path: PropertyKey[]; code: string }[]) {
  return issues.map((issue) => `${issue.path.join(".") || "<root>"}:${issue.code}`);
}
