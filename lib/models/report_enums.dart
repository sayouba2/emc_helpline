/// Business values of a report.
///
/// These used to be bare French strings compared with `==` across the provider
/// and the step screens, which made a typo (or a translation) silently break
/// the wizard's branching logic. They now carry no text at all: display names
/// live in `core/localization/report_enum_labels.dart`, keyed off the ARB
/// files, so translating a label cannot affect the wizard's branching.
library;

enum WhoFor { self, someoneElse }

enum AgeGroup {
  child,
  teen,
  adult,
  undisclosed;

  /// The EMC chatbot is designed for the 12+ audience only.
  bool get isChatbotEligible => this == AgeGroup.teen || this == AgeGroup.adult;
}

enum Gender { female, male, undisclosed }

enum IncidentType {
  hateSpeech,
  discrimination,
  defamation,
  identityTheft,
  intimateImages,
  threat,
  other,
}

enum ReportPlatform {
  whatsapp,
  instagram,
  tiktok,
  facebook,
  onlineGame,
  messenger,
}

enum AssistanceNeed { wanted, none, unsure }

enum AssistanceType { legal, psychological, both, unsure }

enum UrgencyLevel { urgent, notUrgent, unsure }
