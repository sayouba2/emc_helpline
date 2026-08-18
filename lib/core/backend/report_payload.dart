import '../../models/report_enums.dart';
import '../../models/report_model.dart';

/// Turns a report into what `submitReport` expects on the wire.
///
/// Enum values travel as their Dart member names (`AgeGroup.teen` → `"teen"`).
/// The server lists the same names in `functions/src/schema.ts` and refuses
/// anything else, so **renaming a member of `report_enums.dart` is a change of
/// contract**, not a rename. Nothing here is ever displayed — the labels live
/// in the ARB files — so a translation cannot affect what is stored.
Map<String, Object?> reportPayload(ReportModel report) {
  final wantsAssistance = report.assistanceNeeded == AssistanceNeed.wanted;

  return <String, Object?>{
    'whoFor': report.whoFor!.name,
    'ageGroup': report.ageGroup!.name,
    'gender': report.gender!.name,
    'incidentType': report.incidentType!.name,
    'platform': report.platform!.name,
    'urgencyLevel': report.urgencyLevel!.name,
    'assistanceNeeded': report.assistanceNeeded!.name,

    // Empty until the upload endpoint exists — see the note below.
    'evidencePaths': const <String>[],

    if (_isNotBlank(report.evidenceUrl))
      'evidenceUrl': report.evidenceUrl!.trim(),
    if (_isNotBlank(report.description))
      'description': report.description!.trim(),

    // The server drops these anyway when assistance was not requested. They are
    // left out here too, so that a report the user believes is anonymous does
    // not carry their phone number across the network on its way to being
    // discarded.
    if (wantsAssistance && report.assistanceType != null)
      'assistanceType': report.assistanceType!.name,
    if (wantsAssistance && _isNotBlank(report.pseudo))
      'pseudo': report.pseudo!.trim(),
    if (wantsAssistance && _isNotBlank(report.contactPhone))
      'contactPhone': report.contactPhone!.trim(),
  };
}

/// True when this report cannot be filed until screenshots can be uploaded.
///
/// `ReportModel.evidenceFilePaths` holds paths on the phone's own storage.
/// The server only accepts object paths handed out by
/// `requestEvidenceUploadUrl`, which is step 4 of `docs/backend-plan.md` and
/// does not exist yet — so screenshots cannot be sent, and a report whose only
/// evidence is a screenshot fails the server's completeness check.
///
/// Exposed rather than hidden so the gap is visible in code and in tests
/// instead of surfacing as an unexplained rejection. **Step 4 has to land
/// before the client is pointed at production.**
bool needsEvidenceUpload(ReportModel report) =>
    report.evidenceFilePaths.isNotEmpty &&
    !_isNotBlank(report.evidenceUrl) &&
    (report.description?.trim().length ?? 0) < 120;

bool _isNotBlank(String? value) => value != null && value.trim().isNotEmpty;
