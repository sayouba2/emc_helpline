// Console de triage — EMC Helpline.
//
// Aucun accès direct à Firestore : les règles refusent tout, aux agents comme
// au reste du monde. Tout passe par des fonctions appelables, ce qui donne le
// journal d'audit — qui a ouvert quel dossier — sans dépendre de la discipline
// de qui écrit le code client.
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.10.0/firebase-app.js";
import {
  connectAuthEmulator,
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from "https://www.gstatic.com/firebasejs/11.10.0/firebase-auth.js";
import {
  connectFunctionsEmulator,
  getFunctions,
  httpsCallable,
} from "https://www.gstatic.com/firebasejs/11.10.0/firebase-functions.js";

import { firebaseConfig, REGION } from "./config.js";

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const functions = getFunctions(app, REGION);

// Servie depuis la machine locale, la console s'adresse aux émulateurs. Le
// test porte sur l'hôte plutôt que sur un drapeau : une console déployée n'est
// jamais servie depuis localhost, donc elle ne peut pas basculer par accident.
const LOCAL = ["localhost", "127.0.0.1", "[::1]"].includes(location.hostname);
if (LOCAL) {
  connectAuthEmulator(auth, `http://${location.hostname}:9099`, {
    disableWarnings: true,
  });
  connectFunctionsEmulator(functions, location.hostname, 5001);
}

const call = (name) => httpsCallable(functions, name);
const $ = (id) => document.getElementById(id);

// ── Vocabulaire ────────────────────────────────────────────────────────────
//
// Les valeurs voyagent en identifiants d'enum, jamais en texte : traduire un
// libellé ne peut donc pas casser un filtre.

const STATUSES = ["received", "inReview", "contacted", "closed"];
const STATUS = {
  received: "Reçu",
  inReview: "En examen",
  contacted: "Contacté",
  closed: "Clos",
};
const INCIDENT = {
  hateSpeech: "Discours haineux",
  discrimination: "Discrimination",
  defamation: "Diffamation",
  identityTheft: "Usurpation d'identité",
  intimateImages: "Images intimes",
  threat: "Menace",
  other: "Autre",
};
const URGENCY = { urgent: "Urgent", notUrgent: "Non urgent", unsure: "Indéterminée" };
const AGE = {
  child: "Moins de 12 ans",
  teen: "12 à 17 ans",
  adult: "18 ans et plus",
  undisclosed: "Non précisé",
};
const GENDER = { female: "Féminin", male: "Masculin", undisclosed: "Non précisé" };
const WHO = { self: "Pour elle ou lui-même", someoneElse: "Pour quelqu'un d'autre" };
const ASSISTANCE = { wanted: "Demandé", none: "Refusé", unsure: "Indécis" };
const ASSISTANCE_TYPE = {
  legal: "Juridique",
  psychological: "Psychologique",
  both: "Les deux",
  unsure: "Indécis",
};
const PLATFORM = {
  whatsapp: "WhatsApp",
  instagram: "Instagram",
  tiktok: "TikTok",
  facebook: "Facebook",
  onlineGame: "Jeu en ligne",
  messenger: "Messenger",
};

const label = (map, key) => map[key] ?? key ?? "—";

const dateOf = (iso) =>
  iso
    ? new Date(iso).toLocaleString("fr-FR", {
        day: "2-digit",
        month: "short",
        hour: "2-digit",
        minute: "2-digit",
      })
    : "—";

/** Jours avant la suppression automatique. */
const daysLeft = (iso) =>
  iso === null || iso === undefined
    ? null
    : Math.ceil((new Date(iso) - Date.now()) / 86400000);

const el = (tag, className, text) => {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
};

/**
 * Un message d'échec dit ce qui s'est passé et quoi faire, jamais « une erreur
 * est survenue ». Remplace les `alert()` qui bloquaient la page.
 */
function notice(host, text) {
  host.replaceChildren();
  if (text) host.append(el("p", "notice", text));
  host.hidden = !text;
}

function stateBlock(host, title, body) {
  const wrap = el("div", "state");
  wrap.append(el("h3", null, title));
  if (body) wrap.append(el("p", null, body));
  host.replaceChildren(wrap);
}

// ── Connexion ──────────────────────────────────────────────────────────────

$("signin-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const button = $("signin-button");
  button.disabled = true;
  notice($("signin-notice"), null);
  try {
    await signInWithEmailAndPassword(auth, $("email").value, $("password").value);
  } catch {
    // Volontairement identique pour un compte inconnu et un mot de passe faux :
    // sinon le formulaire dit qui a un compte ici.
    notice(
      $("signin-notice"),
      "Adresse ou mot de passe incorrect. Vérifiez, puis réessayez.",
    );
  } finally {
    button.disabled = false;
  }
});

onAuthStateChanged(auth, async (user) => {
  if (!user) {
    $("signin").hidden = false;
    $("console").hidden = true;
    $("session").replaceChildren();
    return;
  }

  // Le rôle vit dans le jeton, pas dans la page : un agent révoqué le perd à la
  // prochaine actualisation, et le serveur refuse de toute façon.
  const token = await user.getIdTokenResult();
  if (token.claims.role !== "agent") {
    notice(
      $("signin-notice"),
      `${user.email} n'a pas accès à la console. Demandez au responsable technique de l'autoriser.`,
    );
    await signOut(auth);
    return;
  }

  $("signin").hidden = true;
  $("console").hidden = false;

  const session = $("session");
  session.replaceChildren();
  if (LOCAL) {
    const badge = el("span", "chip inReview", "émulateurs");
    badge.title = "Cette console lit la base locale, pas le vrai projet.";
    session.append(badge);
  }
  session.append(el("span", "session-email", user.email));
  const out = el("button", "quiet", "Se déconnecter");
  out.addEventListener("click", () => signOut(auth));
  session.append(out);

  buildFilters();
  reload();
});

// ── Filtres ────────────────────────────────────────────────────────────────

let activeStatus = "";
let cursor = null;
let loading = false;
let openId = null;

function buildFilters() {
  const host = $("filters");
  host.replaceChildren();
  for (const [value, text] of [["", "Tous"], ...STATUSES.map((s) => [s, STATUS[s]])]) {
    const button = el("button", "filter", text);
    button.type = "button";
    button.setAttribute("aria-pressed", String(value === activeStatus));
    button.dataset.status = value;
    button.append(el("span", "count", ""));
    button.addEventListener("click", () => {
      activeStatus = value;
      for (const other of host.children) {
        other.setAttribute("aria-pressed", String(other.dataset.status === value));
      }
      reload();
    });
    host.append(button);
  }
}

function setCount(status, value) {
  const button = $("filters").querySelector(`[data-status="${status}"] .count`);
  if (button) button.textContent = value === null ? "" : value;
}

// ── La file ────────────────────────────────────────────────────────────────

function reload() {
  cursor = null;
  $("ledger").replaceChildren();
  notice($("queue-notice"), null);
  loadPage();
}

async function loadPage() {
  if (loading) return;
  loading = true;
  $("more").disabled = true;

  try {
    const query = {};
    if (activeStatus) query.status = activeStatus;
    if (cursor) query.startAfter = cursor;

    const { data } = await call("listReports")(query);
    for (const report of data.reports) $("ledger").append(row(report));

    cursor = data.cursor;
    $("more").hidden = data.reports.length === 0 || !cursor;
    setCount(activeStatus, $("ledger").children.length);

    if ($("ledger").children.length === 0) {
      stateBlock(
        $("ledger"),
        activeStatus ? `Aucun dossier « ${STATUS[activeStatus]} »` : "Aucun dossier",
        activeStatus
          ? "Changez de filtre pour voir les autres."
          : "Les signalements déposés depuis l'application apparaîtront ici.",
      );
    }
  } catch (error) {
    notice(
      $("queue-notice"),
      `La file n'a pas pu être chargée : ${error?.message ?? error}. Rechargez la page.`,
    );
  } finally {
    loading = false;
    $("more").disabled = false;
  }
}

/**
 * Une ligne de dossier.
 *
 * Deux marges portent tout le triage : le rail d'urgence à gauche, l'échéance
 * à droite. Le milieu reste calme — ce n'est pas là qu'on décide.
 */
function row(report) {
  const item = el("li", "case");
  item.dataset.urgency = report.urgencyLevel ?? "";
  item.dataset.id = report.id;
  item.setAttribute("role", "option");
  item.setAttribute("aria-selected", String(report.id === openId));
  item.tabIndex = -1;

  const body = el("div");
  const line = el("div");
  line.append(el("span", "case-type", label(INCIDENT, report.incidentType)));
  if (report.urgencyLevel === "urgent") {
    line.append(el("span", "case-urgent", "Urgent"));
  }
  body.append(line);
  body.append(
    el(
      "div",
      "case-meta",
      [
        dateOf(report.createdAt),
        label(PLATFORM, report.platform),
        report.evidenceCount === 1
          ? "1 preuve"
          : `${report.evidenceCount} preuves`,
      ].join("  ·  "),
    ),
  );
  item.append(body);

  const edge = el("div", "case-edge");
  edge.append(el("span", `chip ${report.status}`, label(STATUS, report.status)));
  const left = daysLeft(report.expiresAt);
  if (left !== null) {
    const stamp = el("span", "expiry", `${left} j`);
    stamp.title = `Suppression automatique dans ${left} jours`;
    if (left <= 7) stamp.dataset.soon = "true";
    edge.append(stamp);
  }
  item.append(edge);

  item.addEventListener("click", () => openCase({ reportId: report.id }));
  return item;
}

$("more").addEventListener("click", () => loadPage());

// Un agent qui descend trente dossiers ne devrait pas avoir à viser à la
// souris à chaque fois.
$("ledger").addEventListener("keydown", (event) => {
  const rows = [...$("ledger").querySelectorAll(".case")];
  if (rows.length === 0) return;
  const current = rows.findIndex((r) => r.getAttribute("aria-selected") === "true");

  if (event.key === "ArrowDown" || event.key === "ArrowUp") {
    event.preventDefault();
    const next = Math.min(
      rows.length - 1,
      Math.max(0, current + (event.key === "ArrowDown" ? 1 : -1)),
    );
    rows[next].scrollIntoView({ block: "nearest" });
    openCase({ reportId: rows[next].dataset.id });
  }
});

// ── Ouvrir par numéro de référence ─────────────────────────────────────────

$("lookup-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const code = $("lookup-code").value.trim();
  if (code) openCase({ referenceCode: code });
});

// ── Le dossier ─────────────────────────────────────────────────────────────

async function openCase(query) {
  const host = $("file");
  $("console").dataset.reading = "true";
  stateBlock(host, "Ouverture…");

  let report;
  try {
    ({ data: report } = await call("getReport")(query));
  } catch (error) {
    const missing = String(error?.code ?? "").includes("not-found");
    stateBlock(
      host,
      missing ? "Aucun dossier ne porte ce numéro" : "Ouverture impossible",
      missing
        ? "Vérifiez le numéro tel qu'il a été dicté, puis réessayez."
        : `${error?.message ?? error}`,
    );
    return;
  }

  openId = report.id;
  for (const item of $("ledger").querySelectorAll(".case")) {
    item.setAttribute("aria-selected", String(item.dataset.id === report.id));
  }

  host.replaceChildren(dossier(report));
  host.scrollTop = 0;
}

function dossier(report) {
  const article = el("article", "dossier");
  article.dataset.urgency = report.urgencyLevel ?? "";

  article.append(el("p", "eyebrow", "Dossier"));
  article.append(el("h2", null, report.id));

  // La ligne d'audit, montrée à l'agent lui-même. Pas un avertissement : un
  // fait, dans le même registre que le reste du dossier.
  article.append(
    el(
      "p",
      "audit",
      `Ouverture enregistrée — ${auth.currentUser.email}, ${new Date().toLocaleString("fr-FR", { dateStyle: "medium", timeStyle: "short" })}`,
    ),
  );

  article.append(pipeline(report.status));
  article.append(facts(report));

  if (report.description) {
    article.append(el("h3", "section-title", "Ce qui s'est passé"));
    article.append(el("p", "account", report.description));
  }

  if (report.evidenceUrls?.length) {
    article.append(
      el("h3", "section-title", `Preuves (${report.evidenceUrls.length})`),
    );
    const list = el("ul", "evidence");
    for (const url of report.evidenceUrls) {
      const item = el("li");
      const link = el("a");
      link.href = url;
      link.target = "_blank";
      link.rel = "noopener";
      const img = el("img");
      // Liens signés, valables quinze minutes : la console montre les preuves,
      // elle ne les publie pas.
      img.src = url;
      img.alt = "Capture jointe au signalement";
      img.loading = "lazy";
      link.append(img);
      item.append(link);
      list.append(item);
    }
    article.append(list);
  }

  article.append(actions(report));
  return article;
}

/** Reçu → examen → contacté → clos. Une vraie séquence, dessinée comme telle. */
function pipeline(status) {
  const list = el("ol", "pipeline");
  const index = STATUSES.indexOf(status);
  STATUSES.forEach((step, position) => {
    const item = el("li", null, STATUS[step]);
    if (position < index) item.dataset.done = "true";
    if (position === index) item.setAttribute("aria-current", "step");
    list.append(item);
  });
  return list;
}

function facts(report) {
  const list = el("dl", "facts");

  const add = (term, value, mono) => {
    if (value === undefined || value === null || value === "") return;
    const wrap = el("div", "fact");
    wrap.append(el("dt", null, term));
    wrap.append(el("dd", mono ? "mono" : null, value));
    list.append(wrap);
  };

  const left = daysLeft(report.expiresAt);
  add("Déposé le", dateOf(report.createdAt), true);
  add(
    "Suppression",
    left === null ? null : `dans ${left} jours`,
    true,
  );
  add("Signale", label(WHO, report.whoFor));
  add("Âge", label(AGE, report.ageGroup));
  add("Genre", label(GENDER, report.gender));
  add("Type", label(INCIDENT, report.incidentType));
  add("Plateforme", label(PLATFORM, report.platform));
  add("Urgence", label(URGENCY, report.urgencyLevel));
  add("Accompagnement", label(ASSISTANCE, report.assistanceNeeded));
  add("Type d'aide", report.assistanceType && label(ASSISTANCE_TYPE, report.assistanceType));
  add("Pseudo", report.pseudo);
  add("Téléphone", report.contactPhone, true);
  add("Lien", report.evidenceUrl, true);

  return list;
}

function actions(report) {
  const bar = el("div", "actions");
  const index = STATUSES.indexOf(report.status);
  const next = STATUSES[index + 1];

  // L'action principale est la suivante dans la filière. Les autres restent
  // possibles, en retrait : un dossier ne progresse pas toujours en ligne
  // droite.
  if (next) {
    const advance = el("button", null, `Marquer « ${STATUS[next]} »`);
    advance.addEventListener("click", () => changeStatus(report.id, next, advance));
    bar.append(advance);
  }

  for (const status of STATUSES) {
    if (status === report.status || status === next) continue;
    const button = el("button", "quiet", STATUS[status]);
    button.addEventListener("click", () => changeStatus(report.id, status, button));
    bar.append(button);
  }

  bar.append(el("span", "spacer"));

  const remove = el("button", "grave", "Supprimer");
  remove.addEventListener("click", () => deleteCase(report.id));
  bar.append(remove);

  return bar;
}

async function changeStatus(reportId, status, button) {
  button.disabled = true;
  try {
    await call("setReportStatus")({ reportId, status });
    await openCase({ reportId });
    reload();
  } catch (error) {
    stateBlock(
      $("file"),
      "Le statut n'a pas changé",
      `${error?.message ?? error}. Le dossier est inchangé.`,
    );
  }
}

async function deleteCase(reportId) {
  const reason = prompt("Motif de la suppression (conservé au journal) :");
  if (!reason || reason.trim().length < 3) return;
  // Les captures partent avec le dossier ; la ligne du journal reste.
  if (
    !confirm(
      "Le dossier et ses captures seront supprimés définitivement. Continuer ?",
    )
  ) {
    return;
  }

  try {
    await call("deleteReport")({ reportId, reason });
    openId = null;
    stateBlock($("file"), "Dossier supprimé", "Le motif est conservé au journal.");
    reload();
  } catch (error) {
    stateBlock(
      $("file"),
      "Suppression impossible",
      `${error?.message ?? error}. Le dossier est intact.`,
    );
  }
}

// L'écran de droite au démarrage : une consigne, pas un vide.
stateBlock(
  $("file"),
  "Choisissez un dossier",
  "La file ne montre ni récit, ni preuves, ni coordonnées. Ouvrir un dossier est un acte distinct, enregistré avec votre adresse.",
);
