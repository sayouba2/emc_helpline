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
