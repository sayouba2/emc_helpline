import { describe, expect, it } from "vitest";

/**
 * Le parcours complet, appelé exactement comme le fait un client.
 *
 * Les autres suites appellent `submitReportCore` et `trackReportCore` en
 * direct, ce qui saute tout ce qu'il y a autour : l'enveloppe des fonctions
 * appelables, la vérification d'authentification, la limitation de débit, le
 * codage JSON. Ce fichier passe par HTTP, avec un vrai jeton de l'émulateur
 * d'authentification — donc si celui-ci passe et que l'application échoue, le
 * problème est dans le téléphone, pas dans le backend.
 */

/// Les suites tournent sur `demo-emc`, isolé. Surchargeable pour viser une
/// instance déjà démarrée — celle de `npm run backend`, par exemple, qui sert
/// le vrai identifiant du projet parce que c'est celui que l'application
/// appelle.
const PROJECT_ID = process.env.EMULATOR_PROJECT_ID ?? "demo-emc";
const REGION = "europe-west1";
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const FUNCTIONS_HOST = process.env.FUNCTIONS_EMULATOR_HOST ?? "127.0.0.1:5001";

const ready = Boolean(AUTH_HOST && process.env.FIRESTORE_EMULATOR_HOST);

/** Un appareil anonyme, comme celui que crée l'application au premier envoi. */
async function signInAnonymously(): Promise<string> {
  const response = await fetch(
    `http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ returnSecureToken: true }),
    },
  );
  const body = (await response.json()) as { idToken?: string };
  if (!body.idToken) throw new Error(`pas de jeton : ${JSON.stringify(body)}`);
  return body.idToken;
}

/** Appelle une fonction appelable comme le ferait le SDK client. */
async function callFunction(
  name: string,
  data: unknown,
  idToken: string,
): Promise<{ status: number; result?: unknown; error?: unknown }> {
  const response = await fetch(
    `http://${FUNCTIONS_HOST}/${PROJECT_ID}/${REGION}/${name}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${idToken}`,
      },
      body: JSON.stringify({ data }),
    },
  );
  const body = (await response.json()) as Record<string, unknown>;
  return { status: response.status, result: body.result, error: body.error };
}

const report = (overrides: Record<string, unknown> = {}) => ({
  whoFor: "self",
  ageGroup: "teen",
  gender: "undisclosed",
  incidentType: "threat",
  platform: "whatsapp",
  urgencyLevel: "urgent",
  assistanceNeeded: "none",
  evidencePaths: [],
  description: "a".repeat(130),
  ...overrides,
});

const uniqueKey = () =>
  `wf-${Date.now().toString(16)}-${Math.random().toString(16).slice(2, 10)}`;

describe.skipIf(!ready)("le parcours complet, par HTTP", () => {
  it("dépose un signalement et le retrouve par son numéro", async () => {
    const idToken = await signInAnonymously();

    const sent = await callFunction(
      "submitReport",
      { idempotencyKey: uniqueKey(), report: report() },
      idToken,
    );
    expect(sent.error, JSON.stringify(sent.error)).toBeUndefined();

    const referenceCode = (sent.result as { referenceCode: string })
      .referenceCode;
    expect(referenceCode).toMatch(/^EMC(-[0-9A-Z]{4}){3}$/);

    const found = await callFunction(
      "trackReport",
      { referenceCode },
      idToken,
    );
    const tracked = found.result as {
      found: boolean;
      report?: { status: string; incidentType: string };
    };

    expect(tracked.found).toBe(true);
    expect(tracked.report?.status).toBe("received");
    expect(tracked.report?.incidentType).toBe("threat");
  });

  it("retrouve le dossier quel que soit la façon dont le numéro est tapé", async () => {
    const idToken = await signInAnonymously();
    const sent = await callFunction(
      "submitReport",
      { idempotencyKey: uniqueKey(), report: report() },
      idToken,
    );
    const code = (sent.result as { referenceCode: string }).referenceCode;

    for (const typed of [code.toLowerCase(), code.replace(/-/g, ""), ` ${code} `]) {
      const found = await callFunction("trackReport", { referenceCode: typed }, idToken);
      expect((found.result as { found: boolean }).found, typed).toBe(true);
    }
  });

  it("rend le même numéro au réessai, sans ouvrir un second dossier", async () => {
    const idToken = await signInAnonymously();
    const idempotencyKey = uniqueKey();

    const first = await callFunction("submitReport", { idempotencyKey, report: report() }, idToken);
    const retry = await callFunction("submitReport", { idempotencyKey, report: report() }, idToken);

    expect((retry.result as { referenceCode: string }).referenceCode).toBe(
      (first.result as { referenceCode: string }).referenceCode,
    );
  });

  it("dépose un signalement dont la seule preuve est une capture", async () => {
    // Le cas qui échouait en local, et qui ressemblait à une panne aléatoire :
    // un signalement avec lien passait, un signalement avec capture non.
    // L'émulateur de Storage ne sait pas signer d'URL, faute de compte de
    // service — `Cannot sign data without client_email`.
    const idToken = await signInAnonymously();
    const idempotencyKey = uniqueKey();

    const issued = await callFunction(
      "requestEvidenceUploadUrl",
      { idempotencyKey, contentType: "image/png", sizeBytes: 8 },
      idToken,
    );
    expect(issued.error, JSON.stringify(issued.error)).toBeUndefined();

    const upload = issued.result as {
      uploadUrl: string;
      storagePath: string;
      method: string;
      headers: Record<string, string>;
    };

    const written = await fetch(upload.uploadUrl, {
      method: upload.method,
      headers: { "Content-Type": "image/png", ...upload.headers },
      body: Buffer.from("89504e470d0a1a0a", "hex"),
    });
    expect(written.status).toBe(200);

    const sent = await callFunction(
      "submitReport",
      {
        idempotencyKey,
        report: report({ description: undefined, evidencePaths: [upload.storagePath] }),
      },
      idToken,
    );

    expect(sent.error, JSON.stringify(sent.error)).toBeUndefined();
    expect((sent.result as { referenceCode: string }).referenceCode).toMatch(
      /^EMC(-[0-9A-Z]{4}){3}$/,
    );
  });

  it("refuse une capture délivrée pour une autre soumission", async () => {
    // Le contrôle qui compte : un chemin bien formé n'est pas une preuve qu'il
    // a été délivré pour ce signalement-là.
    const idToken = await signInAnonymously();
    const issued = await callFunction(
      "requestEvidenceUploadUrl",
      { idempotencyKey: uniqueKey(), contentType: "image/png", sizeBytes: 8 },
      idToken,
    );
    const other = issued.result as { uploadUrl: string; storagePath: string; method: string; headers: Record<string, string> };
    await fetch(other.uploadUrl, {
      method: other.method,
      headers: { "Content-Type": "image/png", ...other.headers },
      body: Buffer.from("89504e470d0a1a0a", "hex"),
    });

    const sent = await callFunction(
      "submitReport",
      {
        idempotencyKey: uniqueKey(),
        report: report({ evidencePaths: [other.storagePath] }),
      },
      idToken,
    );

    expect((sent.error as { status?: string })?.status).toBe("INVALID_ARGUMENT");
  });

  it("refuse un appel sans authentification", async () => {
    // C'est ce que reçoit un script qui appellerait l'endpoint directement.
    const response = await fetch(
      `http://${FUNCTIONS_HOST}/${PROJECT_ID}/${REGION}/submitReport`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ data: { idempotencyKey: uniqueKey(), report: report() } }),
      },
    );
    const body = (await response.json()) as { error?: { status?: string } };

    expect(body.error?.status).toBe("UNAUTHENTICATED");
  });

  it("refuse un signalement incomplet", async () => {
    const idToken = await signInAnonymously();

    const sent = await callFunction(
      "submitReport",
      { idempotencyKey: uniqueKey(), report: report({ description: "trop court" }) },
      idToken,
    );

    expect((sent.error as { status?: string })?.status).toBe("INVALID_ARGUMENT");
  });

  it("ne trouve rien pour un numéro que personne n'a reçu", async () => {
    const idToken = await signInAnonymously();

    const found = await callFunction(
      "trackReport",
      { referenceCode: "EMC-0000-0000-0000" },
      idToken,
    );

    expect((found.result as { found: boolean }).found).toBe(false);
  });
});

describe("les émulateurs", () => {
  it("sont ce contre quoi ce fichier tourne", () => {
    expect(
      ready,
      "lancer `npm run test:workflow` — l'émulateur d'authentification et celui des fonctions doivent tourner",
    ).toBe(true);
  });
});
