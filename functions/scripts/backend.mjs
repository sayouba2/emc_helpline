/**
 * Démarre les émulateurs Firebase en conservant leurs données.
 *
 *   npm run backend
 *
 * Sans `--import` / `--export-on-exit`, les émulateurs repartent vides à chaque
 * lancement : le compte agent disparaît — « adresse ou mot de passe
 * incorrect », alors que rien n'a changé — et les signalements de test avec.
 *
 * `--import` refuse un dossier absent, d'où le contournement : au premier
 * démarrage on ne passe que `--export-on-exit`, qui le crée en sortant.
 */
import { existsSync } from "node:fs";
import { spawn } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const data = join(root, ".emulator-data");

const args = ["emulators:start", `--export-on-exit=${data}`];
if (existsSync(data)) {
  args.splice(1, 0, `--import=${data}`);
  console.log("Données des émulateurs reprises depuis .emulator-data");
} else {
  console.log(
    "Premier démarrage : .emulator-data sera écrit en quittant.\n" +
      "Quitter avec Ctrl-C — un `kill` brutal n'exporte rien.",
  );
}

// Le binaire local plutôt qu'un firebase-tools global, dont la version pourrait
// ne pas être celle contre laquelle les tests tournent.
const firebase = join(root, "node_modules", ".bin", "firebase");

spawn(firebase, args, { cwd: root, stdio: "inherit" }).on("exit", (code) => {
  process.exitCode = code ?? 0;
});
