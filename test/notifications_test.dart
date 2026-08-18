import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emc_helpline/core/backend/case_notifications.dart';
import 'package:emc_helpline/core/storage/settings_store.dart';
import 'package:emc_helpline/core/utils/reference_code.dart';
import 'package:emc_helpline/l10n/app_localizations.dart';
import 'package:emc_helpline/providers/report_provider.dart';
import 'package:emc_helpline/views/reporting/notification_offer_card.dart';

late SettingsStore _settings;
const String _code = 'EMC-4K7P-W9XM-2QTR';

Future<void> _pumpCard(
  WidgetTester tester,
  ReportProvider provider,
  CaseNotifications notifications,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<ReportProvider>.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NotificationOfferCard(
            referenceCode: _code,
            notifications: notifications,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _settings = await SettingsStore.open();
  });

  group('what the phone subscribes to', () {
    test('carries a hash, never the reference code itself', () {
      final topic = CaseNotifications.topicFor(_code, 'fr')!;

      // The topic name travels to Google as a subscription identifier. The
      // code is the only credential a case has; it must not be in there.
      expect(topic, isNot(contains('4K7P')));
      expect(topic, isNot(contains(ReferenceCode.payloadOf(_code))));
      expect(topic, matches(RegExp(r'^case_[0-9a-f]{64}_fr$')));
    });

    test('matches what the server publishes to', () {
      // functions/src/notifications.ts: `case_${referenceHash}_${language}`,
      // where referenceHash is the sha256 of the payload — the same value the
      // reference index is keyed on.
      final payload = ReferenceCode.payloadOf(_code)!;
      final hash = sha256.convert(utf8.encode(payload)).toString();

      expect(CaseNotifications.topicFor(_code, 'ar'), 'case_${hash}_ar');
    });

    test('is the same however the user typed the code', () {
      final canonical = CaseNotifications.topicFor(_code, 'fr');

      expect(CaseNotifications.topicFor('emc4k7pw9xm2qtr', 'fr'), canonical);
      expect(CaseNotifications.topicFor('  $_code  ', 'fr'), canonical);
    });

    test('refuses to build one from something that is not a code', () {
      expect(CaseNotifications.topicFor('nope', 'fr'), isNull);
    });
  });

  group('turning notifications on', () {
    test('asks the system before subscribing to anything', () async {
      final order = <String>[];
      final notifications = CaseNotifications(
        requestPermission: () async {
          order.add('ask');
          return true;
        },
        subscribe: (topic) async => order.add('subscribe'),
      );

      expect(await notifications.enableFor(_code, 'fr'), isTrue);
      expect(order, ['ask', 'subscribe']);
    });

    test('subscribes to nothing when permission is refused', () async {
      var subscribed = false;
      final notifications = CaseNotifications(
        requestPermission: () async => false,
        subscribe: (_) async => subscribed = true,
      );

      expect(await notifications.enableFor(_code, 'fr'), isFalse);
      expect(subscribed, isFalse);
    });

    test('subscribes in the language the app is running in', () async {
      String? topic;
      final notifications = CaseNotifications(
        requestPermission: () async => true,
        subscribe: (t) async => topic = t,
      );

      await notifications.enableFor(_code, 'ar');

      expect(topic, endsWith('_ar'));
    });
  });

  group('turning them off', () {
    test('discards the token, which drops every topic at once', () async {
      // Rather than unsubscribing one by one — which would mean keeping a list
      // of the cases this device is watching, and that list is exactly what
      // must not exist on a shared phone.
      var discarded = false;
      final notifications = CaseNotifications(
        discardToken: () async => discarded = true,
      );

      await notifications.disableAll();

      expect(discarded, isTrue);
    });
  });

  group('the preference', () {
    test('is off on a fresh install', () async {
      expect(ReportProvider(_settings).notificationsEnabled, isFalse);
    });

    test('survives a restart', () async {
      await ReportProvider(_settings).setNotificationsEnabled(true);

      final afterRestart = ReportProvider(await SettingsStore.open());
      expect(afterRestart.notificationsEnabled, isTrue);
    });

    test('records nothing about which case', () async {
      await ReportProvider(_settings).setNotificationsEnabled(true);

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getKeys().map((k) => '$k=${prefs.get(k)}').join('|');

      expect(stored, isNot(contains('4K7P')));
      expect(stored, isNot(contains('case_')));
    });
  });

  group('what the user is shown before deciding', () {
    testWidgets('the shared-phone risk, above the button', (tester) async {
      final provider = ReportProvider(_settings);
      await _pumpCard(tester, provider, CaseNotifications());
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

      final warning = tester.getTopLeft(find.text(l10n.notifyWarning)).dy;
      final button = tester.getTopLeft(find.text(l10n.notifyEnable)).dy;

      expect(find.text(l10n.notifyWarning), findsOneWidget);
      expect(
        warning,
        lessThan(button),
        reason:
            'someone deciding this has to have read it, not merely could have',
      );
    });

    testWidgets('confirmation once it is on', (tester) async {
      final provider = ReportProvider(_settings);
      await _pumpCard(
        tester,
        provider,
        CaseNotifications(
          requestPermission: () async => true,
          subscribe: (_) async {},
        ),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

      await tester.tap(find.text(l10n.notifyEnable));
      await tester.pumpAndSettle();

      expect(find.text(l10n.notifyEnabled), findsOneWidget);
      expect(provider.notificationsEnabled, isTrue);
    });

    testWidgets('a way back when the phone says no', (tester) async {
      final provider = ReportProvider(_settings);
      await _pumpCard(
        tester,
        provider,
        CaseNotifications(
          requestPermission: () async => false,
          subscribe: (_) async {},
        ),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

      await tester.tap(find.text(l10n.notifyEnable));
      await tester.pumpAndSettle();

      expect(find.text(l10n.notifyRefused), findsOneWidget);
      expect(
        find.text(l10n.notifyEnable),
        findsOneWidget,
        reason: 'the offer stays, so allowing it in settings is not a dead end',
      );
      expect(provider.notificationsEnabled, isFalse);
    });
  });
}
