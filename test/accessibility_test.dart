import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emc_helpline/core/storage/settings_store.dart';
import 'package:emc_helpline/l10n/app_localizations.dart';
import 'package:emc_helpline/main.dart';
import 'package:emc_helpline/views/components/glass_container.dart';
import 'package:emc_helpline/views/splash_screen.dart';

/// Phone-sized surface: the tightest realistic layout, where overflows show up
/// first.
const Size _phone = Size(390, 844);

Future<void> _pumpApp(
  WidgetTester tester, {
  double textScale = 1.0,
  Size size = _phone,
}) async {
  // A stored preference also exercises the persistence path.
  SharedPreferences.setMockInitialValues({'settings.localeLanguageCode': 'fr'});
  final settings = await SettingsStore.open();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: EMCHelplineApp(settings: settings),
    ),
  );
  // Let the opening logo fade out before looking at the app.
  await tester.pump();
  await tester.pump(SplashGate.total);
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('text scaling', () {
    // Android and iOS both let users push text well past 1.0; 2.0 is the
    // accessibility setting people in trouble actually use.
    for (final scale in <double>[1.0, 1.5, 2.0]) {
      testWidgets('home lays out without overflow at ${scale}x', (
        tester,
      ) async {
        await _pumpApp(tester, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('layout', () {
    testWidgets('the bottom navigation bar hugs its content', (tester) async {
      await _pumpApp(tester);

      final bar = tester.getSize(find.byType(GlassContainer).last);
      // It grew to the full screen height once, because an `alignment` on the
      // item Container made it expand into the loose constraints the
      // bottomNavigationBar slot provides. Nothing overflowed, so the other
      // tests stayed green while the app was unusable — and the frosted blur
      // then repainted the whole screen on every frame.
      expect(
        bar.height,
        lessThan(120),
        reason: 'a full-height nav bar means a Container is expanding',
      );
    });
  });

  group('semantics', () {
    testWidgets('the navigation bar exposes labelled, selectable tabs', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpApp(tester);

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      for (final label in [
        l10n.navHome,
        l10n.navReport,
        l10n.navResources,
        l10n.navContact,
      ]) {
        expect(
          find.bySemanticsLabel(label),
          findsWidgets,
          reason: 'tab "$label" must be reachable by a screen reader',
        );
      }

      handle.dispose();
    });

    testWidgets('the logo and the language picker are labelled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpApp(tester);

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.bySemanticsLabel(l10n.a11yAppLogo), findsOneWidget);
      // `AppBar` merges its title subtree into one semantics node, so the
      // picker's label is announced as part of it rather than on its own.
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(l10n.changeLanguage))),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(l10n.a11yCall(l10n.police, '19')),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('tappable targets are at least 48dp', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpApp(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('text contrast meets the WCAG AA guideline', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpApp(tester);

      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });
  });
}
