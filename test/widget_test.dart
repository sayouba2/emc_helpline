import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emc_helpline/core/constants/app_contacts.dart';
import 'package:emc_helpline/core/storage/settings_store.dart';
import 'package:emc_helpline/l10n/app_localizations.dart';
import 'package:emc_helpline/main.dart';

void main() {
  testWidgets('the demonstration notice is shown while no backend exists', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'settings.localeLanguageCode': 'fr',
    });
    await tester.pumpWidget(
      EMCHelplineApp(settings: await SettingsStore.open()),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(
      find.text(l10n.demoNoticeTitle),
      kBackendEnabled ? findsNothing : findsWidgets,
      reason: kBackendEnabled
          ? 'the warning must disappear once reports are really sent'
          : 'a child must not believe a report reached anyone',
    );
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      EMCHelplineApp(settings: await SettingsStore.open()),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('EMC Helpline'), findsWidgets);
  });

  testWidgets('every supported locale resolves and renders', (tester) async {
    for (final locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(
        Localizations(
          locale: locale,
          delegates: AppLocalizations.localizationsDelegates,
          child: Builder(
            builder: (context) => Directionality(
              textDirection: Directionality.of(context),
              child: Text(AppLocalizations.of(context).appTitle),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'locale $locale');
    }
  });

  testWidgets('Arabic lays out right-to-left', (tester) async {
    late TextDirection direction;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('ar'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(
          builder: (context) {
            direction = Directionality.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();
    expect(direction, TextDirection.rtl);
  });
}
