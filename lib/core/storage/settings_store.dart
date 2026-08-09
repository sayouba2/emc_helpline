import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-side storage for user preferences.
///
/// Only preferences live here. Report content — pseudonym, contact details,
/// evidence, what happened — is deliberately **not** persisted: the app targets
/// children who often share a phone with the very person they are reporting,
/// so leaving a readable trail on the device is a safety risk, not a feature.
class SettingsStore {
  static const String _localeKey = 'settings.localeLanguageCode';

  const SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<SettingsStore> open() async =>
      SettingsStore(await SharedPreferences.getInstance());

  /// The language the user explicitly picked, or `null` to follow the device.
  Locale? readLocale() {
    final code = _prefs.getString(_localeKey);
    return code == null ? null : Locale(code);
  }

  Future<void> writeLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(_localeKey);
    } else {
      await _prefs.setString(_localeKey, locale.languageCode);
    }
  }
}
