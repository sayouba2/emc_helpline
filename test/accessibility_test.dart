import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emc_helpline/core/storage/settings_store.dart';
import 'package:emc_helpline/l10n/app_localizations.dart';
import 'package:emc_helpline/main.dart';
import 'package:emc_helpline/views/components/glass_container.dart';
import 'package:emc_helpline/views/components/header_app_bar.dart';
import 'package:emc_helpline/views/splash_screen.dart';

/// Phone-sized surface: the tightest realistic layout, where overflows show up
/// first.
const Size _phone = Size(390, 844);

Future<void> _pumpApp(
  WidgetTester tester, {
  double textScale = 1.0,
  Size size = _phone,
  double topInset = 0,
  double sideInset = 0,
}) async {
  // A stored preference also exercises the persistence path.
  SharedPreferences.setMockInitialValues({
    'settings.localeLanguageCode': 'fr',
    // Ces suites portent sur l'application, pas sur l'écran de premier
    // lancement : elles simulent une installation déjà passée par là.
    'settings.hasSeenOnboarding': true,
  });
  final settings = await SettingsStore.open();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  if (topInset > 0 || sideInset > 0) {
    final padding = FakeViewPadding(
      top: topInset,
      left: sideInset,
      right: sideInset,
    );
    tester.view.padding = padding;
    tester.view.viewPadding = padding;
  }
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      // Built from the view rather than from scratch: a bare MediaQueryData
      // has zero padding and would wipe the status bar / cutout inset the test
      // is trying to exercise.
      data: MediaQueryData.fromView(
        tester.view,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
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
    testWidgets('the header clears the status bar and the display cutout', (
      tester,
    ) async {
      // A centred punch-hole camera sits inside this inset. The header used to
      // set preferredSize without toolbarHeight, so the AppBar laid its content
      // out in the default 56dp and jammed the title under the camera.
      const inset = 120.0;
      await _pumpApp(tester, topInset: inset);

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      final clearance = tester.getTopLeft(find.text(l10n.appTitle)).dy - inset;

      // Not just "below the inset": a cutout can reach a few dp past the status
      // bar, and the title used to sit ~2dp under it. Content is now centred in
      // the reserved height instead of pinned to its top.
      expect(
        clearance,
        greaterThanOrEqualTo(8.0),
        reason: 'the title needs breathing room under a punch-hole camera',
      );
    });

    testWidgets('the header grows with the text scale, within reason', (
      tester,
    ) async {
      await _pumpApp(tester);
      final atNormalScale = tester.getSize(find.byType(HeaderAppBar)).height;

      await _pumpApp(tester, textScale: 2.0);
      final atDoubleScale = tester.getSize(find.byType(HeaderAppBar)).height;

      expect(atDoubleScale, greaterThan(atNormalScale));
      expect(
        atDoubleScale,
        lessThan(atNormalScale * 1.5),
        reason: 'a header that grew unbounded would swallow the screen',
      );
    });

    testWidgets('content clears a side cutout in landscape', (tester) async {
      const inset = 90.0;
      await _pumpApp(
        tester,
        size: const Size(844, 390), // paysage
        sideInset: inset,
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

      // Le fond doit rester pleine largeur…
      expect(tester.getSize(find.byType(HeaderAppBar)).width, 844);

      // …mais rien de lisible ne doit tomber dans la bande de l'encoche.
      for (final finder in [
        find.text(l10n.heroTitle),
        find.text(l10n.emergencyNumbers),
      ]) {
        final rect = tester.getRect(finder);
        expect(
          rect.left,
          greaterThanOrEqualTo(inset),
          reason: 'du texte sous une encoche latérale est illisible',
        );
        expect(rect.right, lessThanOrEqualTo(844 - inset));
      }
    });

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
