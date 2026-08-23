import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emc_helpline/l10n/app_localizations.dart';
import 'package:emc_helpline/views/components/foreground_update_banner.dart';

Future<void> _pump(WidgetTester tester, Stream<void> updates) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => ForegroundUpdateBanner(
        updates: updates,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const Scaffold(body: Text('un écran quelconque')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('une mise à jour reçue app ouverte se voit', (tester) async {
    // Android ne dessine rien de lui-même au premier plan : le message arrive
    // à l'application et n'est affiché par personne. Sans ça, un dossier qui
    // avance pendant que son auteur regarde l'écran ne produisait rien.
    final updates = StreamController<void>();
    await _pump(tester, updates.stream);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    expect(find.text(l10n.notifyInAppUpdate), findsNothing);

    updates.add(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(l10n.notifyInAppUpdate), findsOneWidget);
    await updates.close();
  });

  testWidgets('elle n\'en dit pas plus que la notification', (tester) async {
    // Être dans l'application n'est pas être seul avec elle : le téléphone
    // peut être partagé, ce autour de quoi tout ce produit est bâti.
    final updates = StreamController<void>();
    await _pump(tester, updates.stream);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    updates.add(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final shown = l10n.notifyInAppUpdate.toLowerCase();
    for (final leak in ['emc-', 'reçu', 'en examen', 'contacté', 'clos']) {
      expect(shown.contains(leak), isFalse, reason: leak);
    }
    await updates.close();
  });

  testWidgets('deux messages ne laissent pas deux barres', (tester) async {
    final updates = StreamController<void>();
    await _pump(tester, updates.stream);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    updates.add(null);
    await tester.pump();
    updates.add(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(l10n.notifyInAppUpdate), findsOneWidget);
    await updates.close();
  });

  testWidgets('sans backend, rien n\'écoute et rien ne casse', (tester) async {
    await _pump(tester, const Stream<void>.empty());

    expect(find.text('un écran quelconque'), findsOneWidget);
  });
}
