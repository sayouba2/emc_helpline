import '../../l10n/app_localizations.dart';
import '../utils/validators.dart';
import '../../models/report_enums.dart';

/// Localised display names for the report enums.
///
/// The enums stay pure data — they carry no user-facing text — so a translation
/// can never change the value the wizard branches on.
extension WhoForLabel on WhoFor {
  String label(AppLocalizations l10n) => switch (this) {
    WhoFor.self => l10n.whoForSelf,
    WhoFor.someoneElse => l10n.whoForSomeoneElse,
  };
}

extension AgeGroupLabel on AgeGroup {
  String label(AppLocalizations l10n) => switch (this) {
    AgeGroup.child => l10n.ageChild,
    AgeGroup.teen => l10n.ageTeen,
    AgeGroup.adult => l10n.ageAdult,
    AgeGroup.undisclosed => l10n.ageUndisclosed,
  };
}

extension GenderLabel on Gender {
  String label(AppLocalizations l10n) => switch (this) {
    Gender.female => l10n.genderFemale,
    Gender.male => l10n.genderMale,
    Gender.undisclosed => l10n.genderUndisclosed,
  };
}

extension IncidentTypeLabel on IncidentType {
  String label(AppLocalizations l10n) => switch (this) {
    IncidentType.hateSpeech => l10n.incidentHateSpeech,
    IncidentType.discrimination => l10n.incidentDiscrimination,
    IncidentType.defamation => l10n.incidentDefamation,
    IncidentType.identityTheft => l10n.incidentIdentityTheft,
    IncidentType.intimateImages => l10n.incidentIntimateImages,
    IncidentType.threat => l10n.incidentThreat,
    IncidentType.other => l10n.incidentOther,
  };
}

extension ReportPlatformLabel on ReportPlatform {
  /// Brand names are not translated; only the generic entry is.
  String label(AppLocalizations l10n) => switch (this) {
    ReportPlatform.whatsapp => 'WhatsApp',
    ReportPlatform.instagram => 'Instagram',
    ReportPlatform.tiktok => 'TikTok',
    ReportPlatform.facebook => 'Facebook',
    ReportPlatform.messenger => 'Messenger',
    ReportPlatform.onlineGame => l10n.platformOnlineGame,
  };
}

extension AssistanceNeedLabel on AssistanceNeed {
  String label(AppLocalizations l10n) => switch (this) {
    AssistanceNeed.wanted => l10n.assistanceWanted,
    AssistanceNeed.none => l10n.assistanceNone,
    AssistanceNeed.unsure => l10n.assistanceUnsure,
  };
}

extension AssistanceTypeLabel on AssistanceType {
  String label(AppLocalizations l10n) => switch (this) {
    AssistanceType.legal => l10n.assistanceTypeLegal,
    AssistanceType.psychological => l10n.assistanceTypePsychological,
    AssistanceType.both => l10n.assistanceTypeBoth,
    AssistanceType.unsure => l10n.assistanceTypeUnsure,
  };
}

extension UrgencyLevelLabel on UrgencyLevel {
  String label(AppLocalizations l10n) => switch (this) {
    UrgencyLevel.urgent => l10n.urgencyUrgent,
    UrgencyLevel.notUrgent => l10n.urgencyNotUrgent,
    UrgencyLevel.unsure => l10n.urgencyUnsure,
  };
}

extension ValidationMessageLabel on ValidationMessage {
  String text(AppLocalizations l10n) => switch (this) {
    ValidationMessage.chooseWho => l10n.validationWho,
    ValidationMessage.chooseAge => l10n.validationAge,
    ValidationMessage.chooseGender => l10n.validationGender,
    ValidationMessage.chooseIncident => l10n.validationIncident,
    ValidationMessage.choosePlatform => l10n.validationPlatform,
    ValidationMessage.chooseEvidence => l10n.validationEvidence,
    ValidationMessage.chooseAssistance => l10n.validationAssistance,
    ValidationMessage.chooseAssistanceType => l10n.validationAssistanceType,
    ValidationMessage.chooseUrgency => l10n.validationUrgency,
    ValidationMessage.missingPseudo => l10n.validationPseudo,
    ValidationMessage.missingPhone => l10n.validationPhone,
    ValidationMessage.invalidPhone => l10n.validationInvalidPhone,
    ValidationMessage.invalidUrl => l10n.validationInvalidUrl,
  };
}
