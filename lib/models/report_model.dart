import 'report_enums.dart';

/// Sentinel marking an argument that was not passed at all.
///
/// [ReportModel.copyWith] (and `ReportProvider.updateReport`) need to tell
/// "leave this field untouched" apart from "clear this field". Without it,
/// `copyWith(contactPhone: null)` silently kept the previous phone number,
/// so "Rester 100% Anonyme" and "Supprimer la capture" never actually erased
/// anything.
const Object unsetField = Object();

/// Returns [current] when [value] was omitted, otherwise [value] itself
/// (including `null`, which clears the field).
T? _resolve<T>(Object? value, T? current) =>
    identical(value, unsetField) ? current : value as T?;

class ReportModel {
  final String? referenceCode;
  final WhoFor? whoFor;
  final String? pseudo; // Surnom / Pseudonym for step 1 anonymity
  final AgeGroup? ageGroup;
  final Gender? gender;
  final IncidentType? incidentType;
  final ReportPlatform? platform;
  final String? evidenceUrl;
  final String? evidenceFilePath;
  final bool hasNoEvidence;
  final AssistanceNeed? assistanceNeeded;
  final AssistanceType? assistanceType;
  final String? contactPhone;
  final String? contactEmail;
  final String? contactWhatsapp;
  final UrgencyLevel? urgencyLevel;
  final DateTime? createdAt;

  const ReportModel({
    this.referenceCode,
    this.whoFor,
    this.pseudo,
    this.ageGroup,
    this.gender,
    this.incidentType,
    this.platform,
    this.evidenceUrl,
    this.evidenceFilePath,
    this.hasNoEvidence = false,
    this.assistanceNeeded,
    this.assistanceType,
    this.contactPhone,
    this.contactEmail,
    this.contactWhatsapp,
    this.urgencyLevel,
    this.createdAt,
  });

  /// True once the user has answered the evidence step one way or another —
  /// including by explicitly declaring they have none.
  bool get hasEvidenceAnswer =>
      hasNoEvidence ||
      evidenceFilePath != null ||
      (evidenceUrl != null && evidenceUrl!.trim().isNotEmpty);

  /// True when at least one way of calling the user back was provided.
  bool get hasAnyContactDetail => [
    contactPhone,
    contactEmail,
    contactWhatsapp,
  ].any((value) => value != null && value.trim().isNotEmpty);

  /// The report carries no way of identifying its author.
  ///
  /// There is no `isAnonymous` flag any more: anonymity is not a toggle but a
  /// consequence. A pseudonym plus a phone number is how someone stays
  /// anonymous *and* reachable, and contact details are only ever collected
  /// from people who asked to be accompanied.
  bool get isAnonymous => !hasAnyContactDetail;

  /// The enum-typed fields can be changed but never un-answered, so they take
  /// plain nullable arguments. The free-text fields can be erased by the user,
  /// so they default to [unsetField]: omit the argument to keep the current
  /// value, pass `null` to clear it.
  ReportModel copyWith({
    Object? referenceCode = unsetField,
    WhoFor? whoFor,
    Object? pseudo = unsetField,
    AgeGroup? ageGroup,
    Gender? gender,
    IncidentType? incidentType,
    ReportPlatform? platform,
    Object? evidenceUrl = unsetField,
    Object? evidenceFilePath = unsetField,
    bool? hasNoEvidence,
    AssistanceNeed? assistanceNeeded,
    AssistanceType? assistanceType,
    Object? contactPhone = unsetField,
    Object? contactEmail = unsetField,
    Object? contactWhatsapp = unsetField,
    UrgencyLevel? urgencyLevel,
    Object? createdAt = unsetField,
  }) {
    return ReportModel(
      referenceCode: _resolve(referenceCode, this.referenceCode),
      whoFor: whoFor ?? this.whoFor,
      pseudo: _resolve(pseudo, this.pseudo),
      ageGroup: ageGroup ?? this.ageGroup,
      gender: gender ?? this.gender,
      incidentType: incidentType ?? this.incidentType,
      platform: platform ?? this.platform,
      evidenceUrl: _resolve(evidenceUrl, this.evidenceUrl),
      evidenceFilePath: _resolve(evidenceFilePath, this.evidenceFilePath),
      hasNoEvidence: hasNoEvidence ?? this.hasNoEvidence,
      assistanceNeeded: assistanceNeeded ?? this.assistanceNeeded,
      assistanceType: assistanceType ?? this.assistanceType,
      contactPhone: _resolve(contactPhone, this.contactPhone),
      contactEmail: _resolve(contactEmail, this.contactEmail),
      contactWhatsapp: _resolve(contactWhatsapp, this.contactWhatsapp),
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      createdAt: _resolve(createdAt, this.createdAt),
    );
  }
}
