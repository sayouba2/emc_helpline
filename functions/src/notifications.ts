import { getMessaging } from "firebase-admin/messaging";
import type { Firestore } from "firebase-admin/firestore";

import { COLLECTIONS } from "./config.js";
import { logEvent, logProblem } from "./logging.js";

/**
 * Telling someone their case moved, without telling anyone else anything.
 *
 * This app is used by children who often share a phone, sometimes with the
 * person they are reporting. A notification is the one part of the product that
 * appears **without being asked for**, on a lock screen, in front of whoever is
 * holding the phone. So two rules shape everything here.
 *
 * **No device is ever registered against a case.** Notifications go to an FCM
 * topic whose name is derived from the reference hash. Subscribing is something
 * the phone does on its own; the server never learns which devices are
 * listening, and no token is stored next to a report. The link between a device
 * and a case exists only on that device.
 *
 * **The message says nothing.** No status, no reference number, not even the
 * word "report". Someone reading the lock screen over a child's shoulder learns
 * that an app sent a message. Everything else requires opening the app and
 * typing a code they do not have.
 */

/** FCM topic names accept `[a-zA-Z0-9-_.~%]+`, which a hex hash satisfies. */
function topicFor(referenceHash: string, language: string): string {
  return `case_${referenceHash}_${language}`;
}

/**
 * Deliberately vague, in three languages.
 *
 * The device subscribes to the topic for the language it is running in, so the
 * text arrives already translated without the server ever storing a language
 * preference against a case.
 */
const MESSAGES: Record<string, { title: string; body: string }> = {
  fr: {
    title: "EMC Helpline",
    body: "Tu as une nouvelle information. Ouvre l'application pour la voir.",
  },
  ar: {
    title: "EMC Helpline",
    body: "لديك معلومة جديدة. افتح التطبيق للاطلاع عليها.",
  },
  en: {
    title: "EMC Helpline",
    body: "You have an update. Open the app to see it.",
  },
};

export const NOTIFICATION_LANGUAGES = Object.keys(MESSAGES);

/**
 * Sends to every language topic, because the server does not know which one the
 * device chose — and deliberately never finds out. Two of the three sends reach
 * nobody, which costs nothing and stores nothing.
 */
export async function notifyStatusChange(
  db: Firestore,
  reportId: string,
): Promise<void> {
  const entries = await db
    .collection(COLLECTIONS.referenceIndex)
    .where("reportId", "==", reportId)
    .limit(1)
    .get();

  const referenceHash = entries.docs[0]?.id;
  if (!referenceHash) {
    logProblem({ event: "notify_no_reference", reportId });
    return;
  }

  const messaging = getMessaging();
  await Promise.all(
    NOTIFICATION_LANGUAGES.map(async (language) => {
      const message = MESSAGES[language]!;
      try {
        await messaging.send({
          topic: topicFor(referenceHash, language),
          notification: message,
          android: {
            priority: "high",
            notification: {
              // Collapsed rather than stacked: three status changes should not
              // leave three lines on a lock screen someone else can read.
              tag: "emc-update",
              // No preview text beyond the body above, and nothing in the
              // ticker that a screen reader would announce out loud.
              channelId: "emc_updates",
            },
          },
        });
      } catch (error) {
        // A topic nobody subscribed to is not an error worth failing on: the
        // status change already happened and matters more than the nudge.
        logProblem({
          event: "notify_failed",
          code: (error as { code?: string }).code,
        });
      }
    }),
  );

  logEvent({ event: "notify_sent", reportId });
}
