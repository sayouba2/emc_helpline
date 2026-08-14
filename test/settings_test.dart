import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emc_helpline/core/storage/settings_store.dart';
import 'package:emc_helpline/l10n/app_localizations.dart';
import 'package:emc_helpline/main.dart';
import 'package:emc_helpline/views/settings/legal_document_screen.dart';
import 'package:emc_helpline/views/settings/settings_screen.dart';
import 'package:emc_helpline/views/splash_screen.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'settings.localeLanguageCode': 'fr',
    'settings.hasSeenOnboarding': true,
  });
  final settings = await SettingsStore.open();
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(EMCHelplineApp(settings: settings));
  await tester.pump();
  await tester.pump(SplashGate.total);
  await tester.pumpAndSettle();
}

Future<AppLocalizations> _fr() =>
    AppLocalizations.delegate.load(const Locale('fr'));

void main() {
  testWidgets('settings are reachable from the header', (tester) async {
    await _pumpApp(tester);
    final l10n = await _fr();

    await tester.tap(find.byTooltip(l10n.settingsTitle));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('every store-required document is reachable', (tester) async {
    await _pumpApp(tester);
    final l10n = await _fr();
    await tester.tap(find.byTooltip(l10n.settingsTitle));
    await tester.pumpAndSettle();

    // Google Play refuses an app that collects personal data without these.
    for (final entry in {
      l10n.settingsPrivacy: l10n.privacyTitle,
      l10n.settingsTerms: l10n.termsTitle,
      l10n.settingsData: l10n.dataTitle,
    }.entries) {
      await tester.tap(find.text(entry.key).first);
      await tester.pumpAndSettle();
      expect(find.byType(LegalDocumentScreen), findsOneWidget);
      expect(find.text(entry.value), findsWidgets);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a document with placeholders shows a draft notice', (
    tester,
  ) async {
    final l10n = await _fr();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LegalDocumentScreen(
          title: l10n.privacyTitle,
          sections: [
            (
              title: l10n.privacyControllerTitle,
              body: l10n.privacyControllerBody,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.legalDraftNotice),
      findsOneWidget,
      reason: 'an unfinished clause must not pass for an approved one',
    );
  });

  testWidgets('a finished document shows no draft notice', (tester) async {
    final l10n = await _fr();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LegalDocumentScreen(
          title: l10n.termsTitle,
          sections: [
            (title: l10n.termsPurposeTitle, body: l10n.termsPurposeBody),
            (
              title: l10n.termsNotEmergencyTitle,
              body: l10n.termsNotEmergencyBody,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.legalDraftNotice), findsNothing);
  });

  test('the legal texts still carry their unfinished passages', () async {
    // Fails the day someone fills them in, as a reminder to drop the marker —
    // and fails today if a placeholder is quietly deleted without being written.
    final l10n = await _fr();
    const marker = LegalDocumentScreen.placeholderMarker;

    expect(l10n.privacyControllerBody.contains(marker), isTrue);
    expect(l10n.privacyRightsBody.contains(marker), isTrue);
    expect(l10n.privacyMinorsBody.contains(marker), isTrue);
    expect(l10n.termsLiabilityBody.contains(marker), isTrue);
    expect(l10n.dataSentBody.contains(marker), isTrue);

    // These are factual descriptions of the app's behaviour, not legal drafting.
    expect(l10n.privacyCollectedBody.contains(marker), isFalse);
    expect(l10n.dataOnDeviceBody.contains(marker), isFalse);
    expect(l10n.termsNotEmergencyBody.contains(marker), isFalse);
  });
}
