class ReportModel {
  String? referenceCode;
  String? whoFor;
  String? pseudo; // Surnom / Pseudonym for step 1 anonymity
  String? ageGroup;
  String? gender;
  String? incidentType;
  String? platform;
  String? evidenceUrl;
  String? evidenceFilePath;
  bool hasNoEvidence;
  String? assistanceNeeded;
  String? assistanceType; // Juridique, Psychologique, Les deux
  bool isAnonymous;
  String? contactName;
  String? contactPhone;
  String? contactEmail;
  String? contactWhatsapp;
  String? urgencyLevel;
  DateTime? createdAt;

  ReportModel({
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
    this.isAnonymous = true,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.contactWhatsapp,
    this.urgencyLevel,
    this.createdAt,
  });

  // Backward-compatible Aliases
  String? get ageRange => ageGroup;
  String? get wantsAssistance => assistanceNeeded;
  String? get urgency => urgencyLevel;
  String? get evidenceImagePath => evidenceFilePath;

  ReportModel copyWith({
    String? referenceCode,
    String? whoFor,
    String? pseudo,
    String? ageGroup,
    String? ageRange,
    String? gender,
    String? incidentType,
    String? platform,
    String? evidenceUrl,
    String? evidenceFilePath,
    String? evidenceImagePath,
    bool? hasNoEvidence,
    String? assistanceNeeded,
    String? wantsAssistance,
    String? assistanceType,
    bool? isAnonymous,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? contactWhatsapp,
    String? urgencyLevel,
    String? urgency,
    DateTime? createdAt,
  }) {
    return ReportModel(
      referenceCode: referenceCode ?? this.referenceCode,
      whoFor: whoFor ?? this.whoFor,
      pseudo: pseudo ?? this.pseudo,
      ageGroup: ageRange ?? ageGroup ?? this.ageGroup,
      gender: gender ?? this.gender,
      incidentType: incidentType ?? this.incidentType,
      platform: platform ?? this.platform,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
      evidenceFilePath: evidenceImagePath ?? evidenceFilePath ?? this.evidenceFilePath,
      hasNoEvidence: hasNoEvidence ?? this.hasNoEvidence,
      assistanceNeeded: wantsAssistance ?? assistanceNeeded ?? this.assistanceNeeded,
      assistanceType: assistanceType ?? this.assistanceType,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      contactWhatsapp: contactWhatsapp ?? this.contactWhatsapp,
      urgencyLevel: urgency ?? urgencyLevel ?? this.urgencyLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
