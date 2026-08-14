import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emc_helpline/core/storage/settings_store.dart';
import 'package:emc_helpline/l10n/app_localizations.dart';
import 'package:emc_helpline/main.dart';
import 'package:emc_helpline/views/chatbot/emc_chatbot_screen.dart';
import 'package:emc_helpline/views/splash_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      EMCHelplineApp(settings: await SettingsStore.open()),
    );
    await tester.pump();
    await tester.pump(SplashGate.total);
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

  testWidgets('the splash shows the logo, then hands over to the app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'settings.localeLanguageCode': 'fr',
    });
    await tester.pumpWidget(
      EMCHelplineApp(settings: await SettingsStore.open()),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(
      find.image(const AssetImage('assets/images/emc.png')),
      findsOneWidget,
      reason: 'the opening screen shows the logo alone',
    );
    expect(find.text(l10n.navHome), findsNothing);

    await tester.pump(SplashGate.total);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text(l10n.heroTitle), findsOneWidget);
  });

  testWidgets('the chatbot header carries only the assistant identity', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'settings.localeLanguageCode': 'fr',
      'settings.hasSeenOnboarding': true,
    });
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EmcChatbotScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(l10n.chatbotTitle), findsOneWidget);
    expect(find.text(l10n.chatbotBetaBadge), findsOneWidget);

    // The age qualifier and the partnership banner used to sit here; the header
    // is the assistant's identity and nothing else.
    expect(l10n.chatbotTitle.contains('12'), isFalse);
    expect(find.byType(Image), findsNothing);
  });
}
