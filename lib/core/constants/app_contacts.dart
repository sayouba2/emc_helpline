/// Every number, address and URL the app can reach out to.
///
/// These used to be repeated across five screens, where a change of helpline
/// number would have been easy to apply in four places out of five.
class AppContacts {
  const AppContacts._();

  /// National police emergency number (Morocco).
  static const String police = '19';

  /// Royal gendarmerie emergency number (Morocco).
  static const String gendarmerie = '177';

  /// EMC Helpline WhatsApp line, digits only — [LauncherUtils.openWhatsApp]
  /// builds the wa.me link from it.
  static const String helplineWhatsApp = '212624405889';

  /// Same line, in dialable form.
  static const String helplinePhone = '+212624405889';

  static const String helplineEmail = 'emchelpline@cyberconfiance.ma';

  /// Official national reporting portal.
  static const String reportingPortal = 'https://evigilance.ma/fr/signaler';
  static const String reportingPortalDisplay = 'evigilance.ma/fr/signaler';
}

/// Whether reports actually reach the EMC team.
///
/// There is no backend yet: `submitReport` only appends to an in-memory list.
/// Until one exists, the app must not let a child in danger believe someone was
/// alerted — the UI shows a demonstration notice while this is false.
///
/// Build the real thing with:
/// `flutter build apk --dart-define=EMC_BACKEND_ENABLED=true`
const bool kBackendEnabled = bool.fromEnvironment('EMC_BACKEND_ENABLED');
