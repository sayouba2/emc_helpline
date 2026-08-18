import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emc_helpline/core/storage/settings_store.dart';
import 'package:emc_helpline/l10n/app_localizations.dart';
import 'package:emc_helpline/models/report_enums.dart';
import 'package:emc_helpline/models/submission_outcome.dart';
import 'package:emc_helpline/models/tracking_outcome.dart';
import 'package:emc_helpline/providers/report_provider.dart';
import 'package:emc_helpline/views/tracking/track_request_screen.dart';

late SettingsStore _settings;

const String _code = 'EMC-4K7P-W9XM-2QTR';

ReportProvider _provider({ReportLookup? lookup}) =>
    ReportProvider(_settings, submissionLatency: Duration.zero, lookup: lookup);

TrackedReport _tracked({ReportStatus? status = ReportStatus.inReview}) =>
    TrackedReport(
      referenceCode: _code,
      status: status,
      createdAt: DateTime(2026, 8, 18, 10, 30),
      incidentType: IncidentType.threat,
      urgencyLevel: UrgencyLevel.urgent,
    );

Future<void> _pump(WidgetTester tester, ReportProvider provider) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<ReportProvider>.value(
      value: provider,
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TrackRequestScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _searchFor(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.pump();
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _settings = await SettingsStore.open();
  });

  group('the four things that can come of typing a number', () {
    test('a case that exists', () async {
      final provider = _provider(lookup: (_) async => _tracked());

      final outcome = await provider.lookupReference(_code);

      expect(outcome, isA<TrackingFound>());
      expect((outcome as TrackingFound).report.status, ReportStatus.inReview);
    });

    test('a number that matches nothing', () async {
      final provider = _provider(lookup: (_) async => null);

      expect(await provider.lookupReference(_code), isA<TrackingNotFound>());
    });

    test('something that is not a number at all, without asking', () async {
      // Told apart from "no such case" so a typo reads as a typo — and it costs
      // no lookup, nor any of the rate-limit budget that protects the codes.
      var asked = false;
      final provider = _provider(
        lookup: (_) async {
          asked = true;
          return null;
        },
      );

      expect(
        await provider.lookupReference('REF-EMC-2026-123456'),
        isA<TrackingMalformed>(),
      );
      expect(asked, isFalse);
    });

    test('a lookup that could not be made is never a missing case', () async {
      // The distinction the whole design turns on. Telling a child their report
      // does not exist because the network is down would be its own small
      // catastrophe.
      final provider = _provider(
        lookup: (_) async =>
            throw const SubmissionException(SubmissionFailure.network),
      );

      expect(await provider.lookupReference(_code), isA<TrackingUnavailable>());
    });
  });

  group('without a backend', () {
    test('falls back to this session, so the demo still tracks', () async {
      final provider = _provider()
        ..updateReport(
          whoFor: WhoFor.self,
          ageGroup: AgeGroup.teen,
          gender: Gender.undisclosed,
          incidentType: IncidentType.threat,
          platform: ReportPlatform.whatsapp,
          evidenceFilePaths: const ['/tmp/proof.png'],
          assistanceNeeded: AssistanceNeed.none,
          urgencyLevel: UrgencyLevel.notUrgent,
        );
      final code = await provider.submitReport();

      final outcome = await provider.lookupReference(code!);

      expect(outcome, isA<TrackingFound>());
      expect((outcome as TrackingFound).report.referenceCode, code);
    });

    test('still tells an unknown number apart from a malformed one', () async {
      final provider = _provider();

      expect(await provider.lookupReference(_code), isA<TrackingNotFound>());
      expect(await provider.lookupReference('nope'), isA<TrackingMalformed>());
    });
  });

  group('a newer backend against an older app', () {
    test('an unknown status is shown neutrally, not guessed', () async {
      expect(enumByName(ReportStatus.values, 'escalated'), isNull);
      expect(enumByName(ReportStatus.values, null), isNull);
      expect(enumByName(ReportStatus.values, 42), isNull);
      expect(
        enumByName(ReportStatus.values, 'inReview'),
        ReportStatus.inReview,
      );
    });

    testWidgets('the screen says so rather than showing nothing', (
      tester,
    ) async {
      final provider = _provider(lookup: (_) async => _tracked(status: null));
      await _pump(tester, provider);

      await _searchFor(tester, _code);

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.trackStatusUnknown), findsOneWidget);
    });
  });

  group('what the user sees', () {
    testWidgets('the status of a case that was found', (tester) async {
      final provider = _provider(lookup: (_) async => _tracked());
      await _pump(tester, provider);

      await _searchFor(tester, _code);

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.trackStatusInReview), findsOneWidget);
      // Read back so the user can check it against what they wrote down.
      expect(
        find.byWidgetPredicate((w) => w is SelectableText && w.data == _code),
        findsOneWidget,
      );
    });

    testWidgets('a failed lookup offers a retry, not a verdict', (
      tester,
    ) async {
      final provider = _provider(
        lookup: (_) async =>
            throw const SubmissionException(SubmissionFailure.network),
      );
      await _pump(tester, provider);

      await _searchFor(tester, _code);

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.trackRequestUnavailable), findsOneWidget);
      expect(find.text(l10n.trackRequestRetry), findsOneWidget);
      expect(
        find.text(l10n.trackRequestNotFound),
        findsNothing,
        reason:
            'a lookup that failed says nothing about whether the case exists',
      );
    });

    testWidgets('a typo is told apart from a case that does not exist', (
      tester,
    ) async {
      final provider = _provider(lookup: (_) async => null);
      await _pump(tester, provider);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

      await _searchFor(tester, 'EMC-4K7P');
      expect(find.text(l10n.trackRequestMalformed), findsOneWidget);

      await _searchFor(tester, _code);
      expect(find.text(l10n.trackRequestNotFound), findsOneWidget);
    });

    testWidgets('the wait is shown, and the button cannot be pressed twice', (
      tester,
    ) async {
      final completer = Completer<TrackedReport?>();
      final provider = _provider(lookup: (_) => completer.future);
      await _pump(tester, provider);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

      await tester.enterText(find.byType(TextField), _code);
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text(l10n.trackRequestSearching), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );

      completer.complete(_tracked());
      await tester.pumpAndSettle();
      expect(find.text(l10n.trackStatusInReview), findsOneWidget);
    });
  });
}
