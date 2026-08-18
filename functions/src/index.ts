import { initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions/v2";
import { REGION } from "./config.js";

initializeApp();
setGlobalOptions({ region: REGION, maxInstances: 10 });

export { submitReport } from "./submitReport.js";
