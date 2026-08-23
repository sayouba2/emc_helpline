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
  static const String _notificationsKey = 'settings.notificationsEnabled';
  static const String _onboardingKey = 'settings.hasSeenOnboarding';

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

  /// Whether the user asked to be told when a case moves.
  ///
  /// A preference, not a record: it says nothing about which case, or that
  /// there is one. Off by default — a notification is the one thing this app
  /// does that shows up on a lock screen somebody else might be reading.
  bool readNotificationsEnabled() => _prefs.getBool(_notificationsKey) ?? false;

  Future<void> writeNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_notificationsKey, enabled);
  }

  /// Whether the first-launch screen has been shown.
  ///
  /// Says nothing about the person: only that this installation has already
  /// been told how the app works.
  bool readHasSeenOnboarding() => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> writeHasSeenOnboarding() async {
    await _prefs.setBool(_onboardingKey, true);
  }
}
