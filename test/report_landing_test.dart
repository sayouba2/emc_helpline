import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emc_helpline/core/storage/settings_store.dart';
import 'package:emc_helpline/l10n/app_localizations.dart';
import 'package:emc_helpline/main.dart';
import 'package:emc_helpline/providers/report_provider.dart';
import 'package:emc_helpline/views/reporting/report_landing_screen.dart';
import 'package:emc_helpline/views/splash_screen.dart';
import 'package:emc_helpline/views/tracking/track_request_screen.dart';

Future<ReportProvider> _pumpApp(WidgetTester tester) async {
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
  await tester.pump(const Duration(milliseconds: 600));

  return Provider.of<ReportProvider>(
    tester.element(find.byType(MaterialApp)),
    listen: false,
  );
}

void main() {
  testWidgets('the report tab opens on the choice screen, not the form', (
    tester,
  ) async {
    final provider = await _pumpApp(tester);

    provider.openReportLanding();
    await tester.pumpAndSettle();

    expect(find.byType(ReportLandingScreen), findsOneWidget);
    expect(
      provider.isWizardOpen,
      isFalse,
      reason: 'an eleven-step form is a lot to land on unasked',
    );
  });

  testWidgets('"Faire un signalement" opens the form', (tester) async {
    final provider = await _pumpApp(tester);
    provider.openReportLanding();
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    await tester.tap(find.text(l10n.reportLandingNew));
    await tester.pumpAndSettle();

    expect(provider.isWizardOpen, isTrue);
    expect(find.byType(ReportLandingScreen), findsNothing);
  });

  testWidgets('"Suivre ma demande" opens the tracking screen', (tester) async {
    final provider = await _pumpApp(tester);
    provider.openReportLanding();
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    await tester.tap(find.text(l10n.trackRequest));
    await tester.pumpAndSettle();

    expect(find.byType(TrackRequestScreen), findsOneWidget);
  });

  testWidgets('the home call to action still goes straight to the form', (
    tester,
  ) async {
    final provider = await _pumpApp(tester);

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    await tester.tap(find.text(l10n.reportNow));
    await tester.pumpAndSettle();

    expect(
      provider.isWizardOpen,
      isTrue,
      reason: 'someone who tapped the emergency CTA has already decided',
    );
    expect(provider.currentTab, 1);
  });

  testWidgets('the first step can go back to the choice screen', (
    tester,
  ) async {
    final provider = await _pumpApp(tester);
    provider.startNewReport();
    await tester.pumpAndSettle();
    expect(provider.wizardStep, ReportProvider.stepWho);

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    await tester.tap(find.text(l10n.actionPrevious));
    await tester.pumpAndSettle();

    expect(find.byType(ReportLandingScreen), findsOneWidget);
  });

  testWidgets('no screen mentions the chatbot age threshold', (tester) async {
    // It is an internal routing rule. A child told they are "12+" learns that
    // younger users are treated differently, which is not theirs to carry.
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    for (final text in [
      l10n.chatbotBannerTitle,
      l10n.chatbotBannerBody,
      l10n.chatbotOpenButton,
      l10n.successChatbotTitle,
      l10n.successChatbotBody,
      l10n.chatbotTitle,
    ]) {
      expect(
        text.contains('12'),
        isFalse,
        reason: 'leaks the threshold: $text',
      );
    }
  });
}
