/**
 * Écrit `console/config.js` à partir de `lib/firebase_options.dart`.
 *
 * Les deux doivent désigner le même projet : la console lit les dossiers que
 * l'application dépose. Recopier les valeurs à la main, c'est se garantir une
 * divergence le jour où `flutterfire configure` est relancé — et une console
 * qui pointe vers un projet vide ressemble à une console cassée.
 *
 *   node functions/scripts/console-config.mjs
 */
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const dart = readFileSync(join(root, "lib", "firebase_options.dart"), "utf8");

const web = dart.match(
  /static const FirebaseOptions web = FirebaseOptions\(([\s\S]*?)\);/,
);
if (!web) {
  console.error(
    "Bloc `web` introuvable dans lib/firebase_options.dart.\n" +
      "Lancer `flutterfire configure` en cochant la plateforme Web.",
  );
  process.exit(1);
}

const field = (name) => {
  const found = web[1].match(new RegExp(`${name}: '([^']+)'`));
  if (!found) {
    console.error(`Champ ${name} absent du bloc web.`);
    process.exit(1);
  }
  return found[1];
};

const config = {
  apiKey: field("apiKey"),
  authDomain: field("authDomain"),
  projectId: field("projectId"),
  appId: field("appId"),
};

const region = readFileSync(
  join(root, "functions", "src", "config.ts"),
  "utf8",
).match(/REGION = "([^"]+)"/)[1];

const output = `// Généré par functions/scripts/console-config.mjs — ne pas éditer à la main.
// Régénérer après tout \`flutterfire configure\` :
//   npm run console:config
//
// Ces valeurs ne sont pas secrètes : elles identifient le projet et sont
// embarquées dans n'importe quelle application web Firebase. Ce qui protège la
// console, c'est le claim \`agent\` exigé côté serveur.
export const firebaseConfig = ${JSON.stringify(config, null, 2)};

export const REGION = ${JSON.stringify(region)};
`;

writeFileSync(join(root, "console", "config.js"), output);
console.log(`console/config.js écrit — projet ${config.projectId}, ${region}.`);
