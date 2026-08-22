/**
 * Crée un compte agent **dans l'émulateur**, vérifié et promu, pour ouvrir la
 * console en local.
 *
 *   npm run console:agent
 *
 * Le script est idempotent : il recrée le compte s'il a disparu, remet le mot
 * de passe et repose le claim. À relancer si `npm run backend` a été tué sans
 * exporter ses données — l'émulateur d'authentification les perd alors, et la
 * connexion répond « adresse ou mot de passe incorrect » sans que rien n'ait
 * changé.
 *
 * Rien de tout ceci ne s'applique au vrai projet : le script refuse de démarrer
 * si l'émulateur d'authentification n'est pas joignable, et le SDK admin, une
 * fois `FIREBASE_AUTH_EMULATOR_HOST` posé, ne parle qu'à lui.
 *
 * En production un compte se crée à la main dans la console Firebase, l'adresse
 * se fait vérifier, puis `grant-agent` pose le rôle. Cette lenteur est voulue :
 * la liste des gens qui lisent des récits d'enfants doit être une liste que
 * quelqu'un a décidée.
 */
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");

const EMAIL = process.env.AGENT_EMAIL ?? "agent@cmrpi.ma";
const PASSWORD = process.env.AGENT_PASSWORD ?? "console-locale";
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST ?? "127.0.0.1:9099";

// Posé avant d'initialiser : c'est ce qui garantit qu'aucune de ces écritures
// ne peut atteindre le vrai projet.
process.env.FIREBASE_AUTH_EMULATOR_HOST = AUTH_HOST;

const projectId = readFileSync(join(root, ".firebaserc"), "utf8").match(
  /"default"\s*:\s*"([^"]+)"/,
)[1];

async function main() {
  try {
    await fetch(`http://${AUTH_HOST}/`);
  } catch {
    console.error(
      `L'émulateur d'authentification ne répond pas sur ${AUTH_HOST}.\n` +
        "Lancer `npm run backend` dans un autre terminal d'abord.",
    );
    process.exit(1);
  }

  initializeApp({ projectId });
  const auth = getAuth();

  let user;
  try {
    user = await auth.getUserByEmail(EMAIL);
    console.log(`Compte déjà présent : ${EMAIL}`);
  } catch {
    user = await auth.createUser({ email: EMAIL, password: PASSWORD });
    console.log(`Compte créé : ${EMAIL}`);
  }

  // `requireAgent` refuse une adresse non vérifiée, et l'émulateur n'envoie
  // aucun courriel — la vérification se pose donc directement.
  await auth.updateUser(user.uid, { emailVerified: true, password: PASSWORD });
  await auth.setCustomUserClaims(user.uid, { role: "agent" });

  const after = await auth.getUser(user.uid);
  const ok = after.emailVerified && after.customClaims?.role === "agent";
  console.log(
    `Vérifiée : ${after.emailVerified ? "oui" : "NON"} — ` +
      `rôle : ${after.customClaims?.role ?? "aucun"}`,
  );
  if (!ok) process.exitCode = 1;

  // L'émulateur d'hébergement prend 5000, ou le port libre suivant s'il est
  // occupé — son propre démarrage annonce lequel.
  console.log("\nConsole locale : http://127.0.0.1:5000");
  console.log(`  identifiant  : ${EMAIL}`);
  console.log(`  mot de passe : ${PASSWORD}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
