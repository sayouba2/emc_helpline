import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emc_helpline/core/storage/settings_store.dart';
import 'package:emc_helpline/providers/report_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a fresh install follows the device language', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = ReportProvider(await SettingsStore.open());

    expect(
      provider.locale,
      isNull,
      reason: 'null lets MaterialApp resolve the system locale',
    );
  });

  test('a chosen language survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = ReportProvider(await SettingsStore.open());

    provider.setLocale(const Locale('ar'));
    expect(provider.locale, const Locale('ar'));

    // A new store over the same preferences stands in for a relaunch.
    final afterRestart = ReportProvider(await SettingsStore.open());
    expect(afterRestart.locale, const Locale('ar'));
  });

  test('report content is never written to disk', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.open();
    final provider = ReportProvider(store)
      ..updateReport(pseudo: 'HérosDiscret42', contactPhone: '0612345678');
    provider.setLocale(const Locale('fr'));

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getKeys().map((k) => '$k=${prefs.get(k)}').join('|');
    for (final secret in ['HérosDiscret42', '0612345678']) {
      expect(
        stored.contains(secret),
        isFalse,
        reason: '"$secret" must not be left on a possibly shared device',
      );
    }
  });
}
