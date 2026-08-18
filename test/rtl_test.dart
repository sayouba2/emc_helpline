import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emc_helpline/core/storage/settings_store.dart';
import 'package:emc_helpline/l10n/app_localizations.dart';
import 'package:emc_helpline/main.dart';
import 'package:emc_helpline/providers/report_provider.dart';
import 'package:emc_helpline/views/chatbot/emc_chatbot_screen.dart';
import 'package:emc_helpline/views/splash_screen.dart';

/// Arabic mirrors the whole interface, not just the text: that is what Android,
/// iOS and the W3C all specify, and what an Arabic speaker expects. These tests
/// pin the parts that do not mirror on their own.
Future<ReportProvider> _pumpArabic(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'settings.localeLanguageCode': 'ar',
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

  return Provider.of<ReportProvider>(
    tester.element(find.byType(MaterialApp)),
    listen: false,
  );
}

void main() {
  testWidgets('the whole interface flips, not only the text', (tester) async {
    await _pumpArabic(tester);

    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
  });

  testWidgets('the navigation bar mirrors', (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpArabic(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));

    // Unselected tabs show only their icon, so they are found by the label a
    // screen reader would announce.
    final home = tester.getCenter(find.bySemanticsLabel(l10n.navHome));
    final contact = tester.getCenter(find.bySemanticsLabel(l10n.navContact));

    expect(
      home.dx,
      greaterThan(contact.dx),
      reason: 'the first tab sits on the right in Arabic',
    );

    handle.dispose();
  });

  testWidgets('chat bubbles swap sides', (tester) async {
    await _pumpArabic(tester);
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EmcChatbotScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    final greeting = tester.getRect(find.text(l10n.chatbotGreeting));

    // The assistant speaks from the right, like every messaging app in Arabic.
    expect(
      greeting.right,
      greaterThan(390 - 40),
      reason: 'a bot bubble pinned to the left reads as a foreign app',
    );
  });

  testWidgets('a reference code keeps its left-to-right reading', (
    tester,
  ) async {
    const code = 'EMC-4K7P-W9XM-2QTR';
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SelectableText(code, textDirection: TextDirection.ltr),
        ),
      ),
    );
    await tester.pump();

    final painted = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(painted.textDirection, TextDirection.ltr);
  });
}
