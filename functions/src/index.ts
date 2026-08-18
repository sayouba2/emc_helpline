import { initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions/v2";
import { REGION } from "./config.js";

initializeApp();
setGlobalOptions({ region: REGION, maxInstances: 10 });

export {
  deleteReport,
  getReport,
  listReports,
  setReportStatus,
} from "./console.js";
export { requestEvidenceUploadUrl } from "./evidence.js";
export { onReportDeleted } from "./retention.js";
export { submitReport } from "./submitReport.js";
export { trackReport } from "./trackReport.js";
