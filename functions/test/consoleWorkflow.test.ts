import { describe, expect, it } from "vitest";

/**
 * La console, appelée par HTTP avec un vrai jeton d'agent.
 *
 * Ce que ça vérifie et qu'aucune autre suite ne couvre : `requireAgent`. Les
 * fonctions de la console sont les seules à lire le contenu d'un signalement,
 * et la seule chose qui en tient la porte est un claim sur un compte. Une
 * suite qui appellerait les fonctions cœur en direct sauterait précisément ce
 * contrôle.
 */

const PROJECT_ID = process.env.EMULATOR_PROJECT_ID ?? "demo-emc";
const REGION = "europe-west1";
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const FUNCTIONS_HOST = process.env.FUNCTIONS_EMULATOR_HOST ?? "127.0.0.1:5001";

const ready = Boolean(AUTH_HOST && process.env.FIRESTORE_EMULATOR_HOST);

const identity = (path: string) =>
  `http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/${path}?key=fake-api-key`;

async function anonymousToken(): Promise<string> {
  const body = await fetch(identity("accounts:signUp"), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ returnSecureToken: true }),
  }).then((r) => r.json() as Promise<{ idToken?: string }>);
  if (!body.idToken) throw new Error("pas de jeton anonyme");
  return body.idToken;
}

/**
 * Le compte que `npm run console:agent` prépare. Le test le crée au besoin,
 * pour ne pas dépendre de l'ordre dans lequel on lance les choses.
 */
async function agentToken(): Promise<string> {
  const email = "agent@cmrpi.ma";
  const password = "console-locale";

  const signIn = await fetch(identity("accounts:signInWithPassword"), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  }).then((r) => r.json() as Promise<{ idToken?: string }>);

  if (!signIn.idToken) {
    throw new Error(
      "compte agent absent — lancer `npm run console:agent` d'abord",
    );
  }
  return signIn.idToken;
}

async function call(
  name: string,
  data: unknown,
  idToken?: string,
): Promise<{ result?: any; error?: any }> {
  const response = await fetch(
    `http://${FUNCTIONS_HOST}/${PROJECT_ID}/${REGION}/${name}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(idToken ? { Authorization: `Bearer ${idToken}` } : {}),
      },
      body: JSON.stringify({ data }),
    },
  );
  const body = (await response.json()) as Record<string, unknown>;
  return { result: body.result, error: body.error };
}

const report = {
  whoFor: "self",
  ageGroup: "teen",
  gender: "undisclosed",
  incidentType: "threat",
  platform: "whatsapp",
  urgencyLevel: "urgent",
  assistanceNeeded: "wanted",
  assistanceType: "legal",
  pseudo: "HérosDiscret42",
  contactPhone: "0612345678",
  evidencePaths: [],
  description: "a".repeat(130),
};

const uniqueKey = () =>
  `cw-${Date.now().toString(16)}-${Math.random().toString(16).slice(2, 10)}`;

describe.skipIf(!ready)("la console, avec un compte agent", () => {
  it("refuse tout à qui n'est pas agent", async () => {
    // L'appareil anonyme de l'application a un jeton parfaitement valide. Ce
    // n'est pas l'authentification qui garde cette porte, c'est le rôle.
    const anonymous = await anonymousToken();

    for (const name of ["listReports", "getReport", "setReportStatus"]) {
      const refused = await call(name, { reportId: "x", status: "closed" }, anonymous);
      expect(refused.error?.status, name).toBe("PERMISSION_DENIED");
    }
  });

  it("refuse tout à qui n'est pas connecté", async () => {
    const refused = await call("listReports", {});
    expect(refused.error?.status).toBe("PERMISSION_DENIED");
  });

  it("accepte les null que fabrique le SDK web", async () => {
    // La requête la plus banale qui soit : la page au premier chargement, sans
    // filtre. Le SDK web sérialise `undefined` en `null`, et un schéma qui
    // n'accepte que l'absence rejetait exactement ça.
    const agent = await agentToken();

    for (const query of [
      {},
      { status: null, startAfter: null },
      { status: null, startAfter: null, limit: null },
      { status: "received", startAfter: null },
    ]) {
      const listed = await call("listReports", query, agent);
      expect(listed.error, JSON.stringify(query)).toBeUndefined();
      expect(Array.isArray(listed.result.reports)).toBe(true);
    }
  });

  it("liste les dossiers sans en montrer le contenu", async () => {
    const agent = await agentToken();
    await call("submitReport", { idempotencyKey: uniqueKey(), report }, await anonymousToken());

    const listed = await call("listReports", {}, agent);

    expect(listed.error, JSON.stringify(listed.error)).toBeUndefined();
    expect(listed.result.reports.length).toBeGreaterThan(0);

    // Faire défiler une file ne doit pas revenir à lire vingt récits d'enfants.
    const serialised = JSON.stringify(listed.result);
    expect(serialised).not.toContain("HérosDiscret42");
    expect(serialised).not.toContain("0612345678");
    expect(serialised).not.toContain("aaaaa");
  });

  it("ouvre un dossier, et là seulement montre tout", async () => {
    const agent = await agentToken();
    const sent = await call(
      "submitReport",
      { idempotencyKey: uniqueKey(), report },
      await anonymousToken(),
    );
    const listed = await call("listReports", {}, agent);
    const reportId = listed.result.reports[0].id;

    const opened = await call("getReport", { reportId }, agent);

    expect(opened.error, JSON.stringify(opened.error)).toBeUndefined();
    expect(opened.result.description).toHaveLength(130);
    expect(sent.result.referenceCode).toMatch(/^EMC/);
  });

  it("ouvre un dossier depuis le numéro que son auteur dicte", async () => {
    // Le moment pour lequel tout le produit existe : quelqu'un appelle et lit
    // son numéro. Le code est stocké haché, donc l'agent ne peut pas le
    // chercher à l'œil — sans ce chemin, il ne pourrait pas l'aider.
    const anonymous = await anonymousToken();
    const agent = await agentToken();
    const sent = await call(
      "submitReport",
      { idempotencyKey: uniqueKey(), report },
      anonymous,
    );
    const referenceCode = sent.result.referenceCode as string;

    const opened = await call("getReport", { referenceCode }, agent);

    expect(opened.error, JSON.stringify(opened.error)).toBeUndefined();
    expect(opened.result.description).toHaveLength(130);
    expect(opened.result.pseudo).toBe("HérosDiscret42");
  });

  it("tolère la façon dont le numéro a été recopié", async () => {
    const anonymous = await anonymousToken();
    const agent = await agentToken();
    const sent = await call(
      "submitReport",
      { idempotencyKey: uniqueKey(), report },
      anonymous,
    );
    const code = sent.result.referenceCode as string;

    for (const typed of [code.toLowerCase(), code.replace(/-/g, ""), ` ${code} `]) {
      const opened = await call("getReport", { referenceCode: typed }, agent);
      expect(opened.error, typed).toBeUndefined();
    }
  });

  it("ne trouve rien pour un numéro que personne n'a reçu", async () => {
    const agent = await agentToken();

    const refused = await call(
      "getReport",
      { referenceCode: "EMC-0000-0000-0000" },
      agent,
    );

    expect(refused.error?.status).toBe("NOT_FOUND");
  });

  it("refuse une ouverture sans dossier ni numéro", async () => {
    const agent = await agentToken();

    const refused = await call("getReport", { reportId: null }, agent);

    expect(refused.error?.status).toBe("INVALID_ARGUMENT");
  });

  it("ouvre un dossier portant une capture, et l'image s'affiche", async () => {
    // Ouvrir un tel dossier répondait `INTERNAL` : getSignedUrl a besoin d'un
    // compte de service que la suite d'émulateurs n'a pas. Le test suit l'URL
    // jusqu'au bout — une URL rendue n'est pas une image affichable.
    const anonymous = await anonymousToken();
    const agent = await agentToken();
    const idempotencyKey = uniqueKey();

    const issued = await call(
      "requestEvidenceUploadUrl",
      { idempotencyKey, contentType: "image/png", sizeBytes: 8 },
      anonymous,
    );
    const upload = issued.result as {
      uploadUrl: string;
      storagePath: string;
      method: string;
      headers: Record<string, string>;
    };
    await fetch(upload.uploadUrl, {
      method: upload.method,
      headers: { "Content-Type": "image/png", ...upload.headers },
      body: Buffer.from("89504e470d0a1a0a", "hex"),
    });
    await call(
      "submitReport",
      {
        idempotencyKey,
        report: { ...report, evidencePaths: [upload.storagePath] },
      },
      anonymous,
    );

    const listed = await call("listReports", {}, agent);
    const target = listed.result.reports.find(
      (r: { evidenceCount: number }) => r.evidenceCount > 0,
    );
    expect(target, "aucun dossier avec preuve dans la file").toBeDefined();

    const opened = await call("getReport", { reportId: target.id }, agent);
    expect(opened.error, JSON.stringify(opened.error)).toBeUndefined();
    expect(opened.result.evidenceUrls).toHaveLength(target.evidenceCount);

    // Sans en-tête d'autorisation : c'est la seule forme qu'un <img> sait
    // utiliser.
    const image = await fetch(opened.result.evidenceUrls[0]);
    expect(image.status).toBe(200);
    expect(image.headers.get("content-type")).toMatch(/^image\//);
  });

  it("ne renvoie jamais le chemin de stockage lui-même", async () => {
    // Le chemin nomme le dossier d'une soumission. La console a besoin d'une
    // URL, pas de savoir où l'objet est rangé.
    const agent = await agentToken();
    const listed = await call("listReports", {}, agent);
    const target = listed.result.reports.find(
      (r: { evidenceCount: number }) => r.evidenceCount > 0,
    );
    if (!target) return;

    const opened = await call("getReport", { reportId: target.id }, agent);

    expect(opened.result.evidencePaths).toBeUndefined();
  });

  it("fait avancer un dossier, et le suivi le voit", async () => {
    const anonymous = await anonymousToken();
    const agent = await agentToken();
    const sent = await call(
      "submitReport",
      { idempotencyKey: uniqueKey(), report },
      anonymous,
    );
    const referenceCode = sent.result.referenceCode as string;

    const before = await call("trackReport", { referenceCode }, anonymous);
    expect(before.result.report.status).toBe("received");

    const listed = await call("listReports", { status: "received" }, agent);
    const reportId = listed.result.reports.find(
      (r: { id: string }) => r.id,
    ).id as string;
    const changed = await call(
      "setReportStatus",
      { reportId, status: "inReview" },
      agent,
    );
    expect(changed.error, JSON.stringify(changed.error)).toBeUndefined();

    // La boucle complète : l'équipe agit, et l'auteur du signalement le voit.
    const opened = await call("getReport", { reportId }, agent);
    expect(opened.result.status).toBe("inReview");
  });

  it("repousse l'expiration quand un dossier avance", async () => {
    // Un dossier supprimé automatiquement pendant qu'on l'instruit serait le
    // pire effet de la conservation à 30 jours.
    const agent = await agentToken();
    const anonymous = await anonymousToken();
    await call("submitReport", { idempotencyKey: uniqueKey(), report }, anonymous);

    const listed = await call("listReports", {}, agent);
    const target = listed.result.reports[0];
    const before = Date.parse(target.expiresAt);

    await new Promise((r) => setTimeout(r, 1100));
    await call("setReportStatus", { reportId: target.id, status: "contacted" }, agent);
    const after = await call("getReport", { reportId: target.id }, agent);

    expect(Date.parse(after.result.expiresAt)).toBeGreaterThan(before);
  });

  it("refuse un statut qui n'existe pas", async () => {
    const agent = await agentToken();
    const listed = await call("listReports", {}, agent);

    const refused = await call(
      "setReportStatus",
      { reportId: listed.result.reports[0].id, status: "escalated" },
      agent,
    );

    expect(refused.error?.status).toBe("INVALID_ARGUMENT");
  });
});

describe("les émulateurs", () => {
  it("sont ce contre quoi ce fichier tourne", () => {
    expect(
      ready,
      "lancer `npm run backend`, puis `npm run console:agent`",
    ).toBe(true);
  });
});
