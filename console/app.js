// Console de l'équipe EMC Helpline.
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
  document.title = "EMC Helpline — Console (local)";
}

const call = (name) => httpsCallable(functions, name);
const $ = (id) => document.getElementById(id);

const STATUS_LABELS = {
  received: "Reçu",
  inReview: "En cours d'examen",
  contacted: "Contacté",
  closed: "Clos",
};
const INCIDENT_LABELS = {
  hateSpeech: "Discours haineux",
  discrimination: "Discrimination",
  defamation: "Diffamation",
  identityTheft: "Usurpation d'identité",
  intimateImages: "Images intimes",
  threat: "Menace",
  other: "Autre",
};
const URGENCY_LABELS = { urgent: "Urgent", notUrgent: "Non urgent", unsure: "Ne sait pas" };
const AGE_LABELS = { child: "Moins de 12 ans", teen: "12–17 ans", adult: "18 ans et plus", undisclosed: "Non précisé" };
const ASSISTANCE_LABELS = { wanted: "Demandé", none: "Refusé", unsure: "Ne sait pas" };
const GENDER_LABELS = { female: "Féminin", male: "Masculin", undisclosed: "Non précisé" };
const WHO_LABELS = { self: "Pour lui/elle-même", someoneElse: "Pour quelqu'un d'autre" };

let cursor = null;
let loading = false;

const dateOf = (iso) =>
  iso ? new Date(iso).toLocaleString("fr-FR", { dateStyle: "medium", timeStyle: "short" }) : "—";

/** Combien de jours avant que le dossier soit supprimé automatiquement. */
function daysLeft(expiresAt) {
  if (!expiresAt) return null;
  return Math.ceil((new Date(expiresAt) - Date.now()) / 86400000);
}

$("signin-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  $("signin-error").hidden = true;
  try {
    await signInWithEmailAndPassword(auth, $("email").value, $("password").value);
  } catch {
    // Volontairement identique pour un compte inconnu et un mot de passe faux :
    // sinon le formulaire dit qui a un compte ici.
    $("signin-error").textContent = "Connexion impossible.";
    $("signin-error").hidden = false;
  }
});

onAuthStateChanged(auth, async (user) => {
  if (!user) {
    $("signin").hidden = false;
    $("queue").hidden = true;
    $("detail").hidden = true;
    $("who").textContent = "";
    return;
  }

  // Le rôle vit dans le jeton, pas dans la page : un agent révoqué perd l'accès
  // à la prochaine actualisation du jeton, et le serveur refuse de toute façon.
  const token = await user.getIdTokenResult();
  if (token.claims.role !== "agent") {
    $("who").textContent = user.email;
    $("signin-error").textContent =
      "Ce compte n'a pas accès à la console. Demandez au responsable technique de l'autoriser.";
    $("signin-error").hidden = false;
    await signOut(auth);
    return;
  }

  $("signin").hidden = true;
  $("queue").hidden = false;
  $("who").innerHTML = "";
  if (LOCAL) {
    const badge = document.createElement("span");
    badge.className = "tag received";
    badge.textContent = "émulateurs";
    badge.title = "Cette console lit la base locale, pas le vrai projet.";
    $("who").append(badge, document.createTextNode(" "));
  }
  const label = document.createElement("span");
  label.textContent = user.email + " ";
  const out = document.createElement("button");
  out.className = "ghost";
  out.textContent = "Se déconnecter";
  out.addEventListener("click", () => signOut(auth));
  $("who").append(label, out);

  reload();
});

$("status-filter").addEventListener("change", reload);
$("more").addEventListener("click", () => loadPage());

function reload() {
  cursor = null;
  $("queue-table").querySelector("tbody").innerHTML = "";
  $("detail").hidden = true;
  loadPage();
}

async function loadPage() {
  if (loading) return;
  loading = true;
  $("more").disabled = true;
  try {
    const status = $("status-filter").value || undefined;
    const { data } = await call("listReports")({ status, startAfter: cursor ?? undefined });
    for (const report of data.reports) appendRow(report);
    cursor = data.cursor;
    $("more").hidden = data.reports.length === 0 || !cursor;
  } catch (error) {
    alert("Chargement impossible : " + (error?.message ?? error));
  } finally {
    loading = false;
    $("more").disabled = false;
  }
}

function cell(row, text, className) {
  const td = document.createElement("td");
  td.textContent = text;
  if (className) td.className = className;
  row.append(td);
  return td;
}

function appendRow(report) {
  const row = document.createElement("tr");
  cell(row, dateOf(report.createdAt));
  cell(row, INCIDENT_LABELS[report.incidentType] ?? report.incidentType);
  cell(
    row,
    URGENCY_LABELS[report.urgencyLevel] ?? report.urgencyLevel,
    report.urgencyLevel === "urgent" ? "urgent" : "",
  );
  cell(row, report.platform);
  cell(row, String(report.evidenceCount));

  const statusCell = document.createElement("td");
  const tag = document.createElement("span");
  tag.className = "tag " + report.status;
  tag.textContent = STATUS_LABELS[report.status] ?? report.status;
  statusCell.append(tag);
  row.append(statusCell);

  const left = daysLeft(report.expiresAt);
  // Un dossier supprimé automatiquement pendant qu'on l'instruit serait le pire
  // effet de la conservation à 30 jours. Le compte à rebours est visible, et il
  // repart à zéro dès qu'on change le statut.
  cell(row, left === null ? "—" : `${left} j`, left !== null && left <= 7 ? "expiring" : "");

  const actions = document.createElement("td");
  const open = document.createElement("button");
  open.className = "ghost";
  open.textContent = "Ouvrir";
  open.addEventListener("click", () => openReport(report.id));
  actions.append(open);
  row.append(actions);

  $("queue-table").querySelector("tbody").append(row);
}

function field(list, label, value) {
  if (value === undefined || value === null || value === "") return;
  const wrap = document.createElement("div");
  wrap.className = "field";
  const dt = document.createElement("dt");
  dt.textContent = label;
  const dd = document.createElement("dd");
  dd.textContent = value;
  wrap.append(dt, dd);
  list.append(wrap);
}

async function openReport(reportId) {
  const detail = $("detail");
  detail.hidden = false;
  detail.textContent = "Ouverture…";
  detail.scrollIntoView({ behavior: "smooth" });

  let report;
  try {
    ({ data: report } = await call("getReport")({ reportId }));
  } catch (error) {
    detail.textContent = "Ouverture impossible : " + (error?.message ?? error);
    return;
  }

  detail.innerHTML = "";
  const title = document.createElement("h2");
  title.textContent = "Dossier";
  const notice = document.createElement("p");
  notice.className = "note";
  notice.textContent = "Cette ouverture a été enregistrée avec votre adresse.";
  detail.append(title, notice);

  const list = document.createElement("dl");
  field(list, "Déposé le", dateOf(report.createdAt));
  field(list, "Statut", STATUS_LABELS[report.status] ?? report.status);
  field(list, "Suppression automatique", `${daysLeft(report.expiresAt) ?? "—"} jours`);
  field(list, "Signale", WHO_LABELS[report.whoFor] ?? report.whoFor);
  field(list, "Âge", AGE_LABELS[report.ageGroup] ?? report.ageGroup);
  field(list, "Genre", GENDER_LABELS[report.gender] ?? report.gender);
  field(list, "Type", INCIDENT_LABELS[report.incidentType] ?? report.incidentType);
  field(list, "Plateforme", report.platform);
  field(list, "Urgence", URGENCY_LABELS[report.urgencyLevel] ?? report.urgencyLevel);
  field(list, "Accompagnement", ASSISTANCE_LABELS[report.assistanceNeeded] ?? report.assistanceNeeded);
  field(list, "Type d'aide", report.assistanceType);
  field(list, "Pseudo", report.pseudo);
  field(list, "Téléphone", report.contactPhone);
  field(list, "Lien", report.evidenceUrl);
  detail.append(list);

  if (report.description) {
    const heading = document.createElement("h2");
    heading.textContent = "Récit";
    const story = document.createElement("p");
    story.className = "story";
    story.textContent = report.description;
    detail.append(heading, story);
  }

  if (report.evidenceUrls?.length) {
    const heading = document.createElement("h2");
    heading.textContent = `Captures (${report.evidenceUrls.length})`;
    const shots = document.createElement("div");
    shots.className = "shots";
    for (const url of report.evidenceUrls) {
      const link = document.createElement("a");
      link.href = url;
      link.target = "_blank";
      link.rel = "noopener";
      const img = document.createElement("img");
      // Liens signés, valables quinze minutes : la console montre les preuves,
      // elle ne les publie pas.
      img.src = url;
      img.alt = "Capture jointe au signalement";
      link.append(img);
      shots.append(link);
    }
    detail.append(heading, shots);
  }

  const actions = document.createElement("div");
  actions.className = "actions";
  for (const [status, label] of Object.entries(STATUS_LABELS)) {
    if (status === report.status) continue;
    const button = document.createElement("button");
    button.textContent = "→ " + label;
    button.addEventListener("click", async () => {
      button.disabled = true;
      try {
        await call("setReportStatus")({ reportId, status });
        reload();
      } catch (error) {
        alert("Changement impossible : " + (error?.message ?? error));
        button.disabled = false;
      }
    });
    actions.append(button);
  }

  const remove = document.createElement("button");
  remove.className = "danger";
  remove.textContent = "Supprimer";
  remove.addEventListener("click", async () => {
    const reason = prompt("Motif de la suppression (conservé au journal) :");
    if (!reason || reason.trim().length < 3) return;
    // Les captures partent avec le dossier ; la ligne du journal reste.
    if (!confirm("Le dossier et ses captures seront supprimés définitivement.")) return;
    try {
      await call("deleteReport")({ reportId, reason });
      reload();
    } catch (error) {
      alert("Suppression impossible : " + (error?.message ?? error));
    }
  });
  actions.append(remove);
  detail.append(actions);
}
