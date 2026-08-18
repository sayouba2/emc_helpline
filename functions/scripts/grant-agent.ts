/**
 * Grants or revokes console access.
 *
 * Deliberately not a button in the console. An account that can promote
 * accounts is an account worth stealing, and the people who read children's
 * abuse reports should be a list someone decided on, not one that can grow by
 * itself.
 *
 *   npx tsx scripts/grant-agent.ts grant agent@cmrpi.ma
 *   npx tsx scripts/grant-agent.ts revoke agent@cmrpi.ma
 *   npx tsx scripts/grant-agent.ts list
 *
 * Needs GOOGLE_APPLICATION_CREDENTIALS pointing at a service account key.
 */
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

import { AGENT_ROLE } from "../src/config.js";

const [action, email] = process.argv.slice(2);

initializeApp({ credential: applicationDefault() });
const auth = getAuth();

async function main(): Promise<void> {
  if (action === "list") {
    const { users } = await auth.listUsers(1000);
    const agents = users.filter((u) => u.customClaims?.role === AGENT_ROLE);
    if (agents.length === 0) {
      console.log("No agents.");
      return;
    }
    for (const user of agents) {
      console.log(`${user.email}\t${user.emailVerified ? "verified" : "UNVERIFIED"}`);
    }
    return;
  }

  if (!email || (action !== "grant" && action !== "revoke")) {
    console.error("usage: grant-agent.ts <grant|revoke|list> [email]");
    process.exitCode = 1;
    return;
  }

  const user = await auth.getUserByEmail(email);

  if (action === "grant" && !user.emailVerified) {
    // `requireAgent` refuses an unverified address, so granting one would
    // produce an account that looks authorised and is not.
    console.error(`${email} has not verified their address. Not granting.`);
    process.exitCode = 1;
    return;
  }

  await auth.setCustomUserClaims(user.uid, action === "grant" ? { role: AGENT_ROLE } : null);
  // The claim rides in the ID token, which lives up to an hour. Revoking the
  // refresh tokens forces a new one, so removing access takes effect now
  // rather than at some point within the hour.
  await auth.revokeRefreshTokens(user.uid);

  console.log(`${action === "grant" ? "Granted" : "Revoked"} ${email}.`);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
