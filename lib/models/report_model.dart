class ReportModel {
  String? id;
  String? whoFor; // "Pour moi" | "Pour quelqu'un d'autre"
  String? ageRange; // "<13", "13-17", "18+"
  String? gender; // "Fille / Femme", "Garçon / Homme", "Autre / Ne souhaite pas préciser"
  String? incidentType; // "Haine", "Diffamation", etc.
  String? platform; // "WhatsApp", "Instagram", etc.
  String? evidenceImagePath; // Local path to attached image
  String? evidenceUrl; // Link to content
  bool hasNoEvidence;
  String? wantsAssistance; // "Accompagnement", "Pas d'accompagnement", "Je ne sais pas"
  String? assistanceType; // "Aide juridique", "Aide psychologique", "Les deux"
  String? urgency; // "Oui, c'est urgent", "Non", "Je ne sais pas"
  bool isAnonymous;
  String? contactPhone;
  String? contactEmail;
  String? contactWhatsapp;
  String? referenceCode;
  DateTime? createdAt;

  ReportModel({
    this.id,
    this.whoFor,
    this.ageRange,
    this.gender,
    this.incidentType,
    this.platform,
    this.evidenceImagePath,
    this.evidenceUrl,
    this.hasNoEvidence = false,
    this.wantsAssistance,
    this.assistanceType,
    this.urgency,
    this.isAnonymous = true,
    this.contactPhone,
    this.contactEmail,
    this.contactWhatsapp,
    this.referenceCode,
    this.createdAt,
  });

  ReportModel copyWith({
    String? id,
    String? whoFor,
    String? ageRange,
    String? gender,
    String? incidentType,
    String? platform,
    String? evidenceImagePath,
    String? evidenceUrl,
    bool? hasNoEvidence,
    String? wantsAssistance,
    String? assistanceType,
    String? urgency,
    bool? isAnonymous,
    String? contactPhone,
    String? contactEmail,
    String? contactWhatsapp,
    String? referenceCode,
    DateTime? createdAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      whoFor: whoFor ?? this.whoFor,
      ageRange: ageRange ?? this.ageRange,
      gender: gender ?? this.gender,
      incidentType: incidentType ?? this.incidentType,
      platform: platform ?? this.platform,
      evidenceImagePath: evidenceImagePath ?? this.evidenceImagePath,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
      hasNoEvidence: hasNoEvidence ?? this.hasNoEvidence,
      wantsAssistance: wantsAssistance ?? this.wantsAssistance,
      assistanceType: assistanceType ?? this.assistanceType,
      urgency: urgency ?? this.urgency,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      contactWhatsapp: contactWhatsapp ?? this.contactWhatsapp,
      referenceCode: referenceCode ?? this.referenceCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
