import '../../models/report_enums.dart';
import '../../models/report_model.dart';

/// Turns a report into what `submitReport` expects on the wire.
///
/// Enum values travel as their Dart member names (`AgeGroup.teen` → `"teen"`).
/// The server lists the same names in `functions/src/schema.ts` and refuses
/// anything else, so **renaming a member of `report_enums.dart` is a change of
/// contract**, not a rename. Nothing here is ever displayed — the labels live
/// in the ARB files — so a translation cannot affect what is stored.
Map<String, Object?> reportPayload(
  ReportModel report, {
  List<String> evidencePaths = const [],
}) {
  final wantsAssistance = report.assistanceNeeded == AssistanceNeed.wanted;

  return <String, Object?>{
    'whoFor': report.whoFor!.name,
    'ageGroup': report.ageGroup!.name,
    'gender': report.gender!.name,
    'incidentType': report.incidentType!.name,
    'platform': report.platform!.name,
    'urgencyLevel': report.urgencyLevel!.name,
    'assistanceNeeded': report.assistanceNeeded!.name,

    // Paths in Cloud Storage, handed out by `requestEvidenceUploadUrl` and
    // uploaded before this call. Never `report.evidenceFilePaths`, which are
    // paths on the phone and mean nothing to the server.
    'evidencePaths': evidencePaths,

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

/// Whether this report needs screenshots uploaded before it can be filed.
///
/// `ReportModel.evidenceFilePaths` holds paths on the phone's own storage; the
/// server only accepts object paths handed out by `requestEvidenceUploadUrl`.
/// `EvidenceUploader` turns one into the other before the report is sent.
bool needsEvidenceUpload(ReportModel report) =>
    report.evidenceFilePaths.isNotEmpty;

bool _isNotBlank(String? value) => value != null && value.trim().isNotEmpty;
