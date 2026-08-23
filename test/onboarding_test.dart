import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emc_helpline/core/storage/settings_store.dart';
import 'package:emc_helpline/l10n/app_localizations.dart';
import 'package:emc_helpline/main.dart';
import 'package:emc_helpline/providers/report_provider.dart';
import 'package:emc_helpline/views/main_navigation_screen.dart';
import 'package:emc_helpline/views/onboarding_screen.dart';
import 'package:emc_helpline/views/splash_screen.dart';

Future<void> _launch(WidgetTester tester, {required bool firstTime}) async {
  SharedPreferences.setMockInitialValues({
    'settings.localeLanguageCode': 'fr',
    if (!firstTime) 'settings.hasSeenOnboarding': true,
  });
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(EMCHelplineApp(settings: await SettingsStore.open()));
  await tester.pump();
  await tester.pump(SplashGate.total);
  await tester.pumpAndSettle();
}

Future<AppLocalizations> _fr() =>
    AppLocalizations.delegate.load(const Locale('fr'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('un premier lancement passe par l\'écran d\'accueil', (
    tester,
  ) async {
    await _launch(tester, firstTime: true);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);
  });

  testWidgets('les lancements suivants vont droit à l\'application', (
    tester,
  ) async {
    await _launch(tester, firstTime: false);

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
  });

  testWidgets('« Commencer » ouvre l\'application, et une fois pour toutes', (
    tester,
  ) async {
    await _launch(tester, firstTime: true);
    final l10n = await _fr();

    await tester.tap(find.text(l10n.onboardingStart));
    await tester.pumpAndSettle();

    expect(find.byType(MainNavigationScreen), findsOneWidget);

    // Un nouveau magasin sur les mêmes préférences tient lieu de relance.
    final afterRestart = ReportProvider(await SettingsStore.open());
    expect(afterRestart.hasSeenOnboarding, isTrue);
  });

  testWidgets('il ne demande aucune permission', (tester) async {
    // Android cesse d'afficher la boîte des notifications après deux refus.
    // Un « non » à froid, avant de savoir ce que fait l'application, la grille
    // définitivement — cet écran annonce, il ne demande pas.
    await _launch(tester, firstTime: true);

    // Aucun appel de permission ne peut partir : rien ici ne touche à
    // FirebaseMessaging, et le test tournerait en erreur de canal si c'était
    // le cas.
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'il dit ce qui sera demandé, et ce que ça donne sur un téléphone partagé',
    (tester) async {
      await _launch(tester, firstTime: true);
      final l10n = await _fr();

      expect(find.text(l10n.onboardingNotifyBody), findsOneWidget);
      expect(l10n.onboardingNotifyBody.toLowerCase(), contains('partagé'));
    },
  );

  testWidgets('un numéro d\'urgence avant le texte d\'introduction', (
    tester,
  ) async {
    // Qui est en danger maintenant n'a pas à lire une présentation.
    await _launch(tester, firstTime: true);
    final l10n = await _fr();

    final urgence = tester.getTopLeft(find.text(l10n.onboardingEmergency)).dy;
    final titre = tester.getTopLeft(find.text(l10n.onboardingTitle)).dy;

    expect(urgence, lessThan(titre));
  });

  testWidgets('il tient à 2x la taille du texte', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings.localeLanguageCode': 'fr',
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData.fromView(
          tester.view,
        ).copyWith(textScaler: const TextScaler.linear(2.0)),
        child: EMCHelplineApp(settings: await SettingsStore.open()),
      ),
    );
    await tester.pump();
    await tester.pump(SplashGate.total);
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
