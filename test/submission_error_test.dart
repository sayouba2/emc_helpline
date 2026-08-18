import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emc_helpline/core/storage/settings_store.dart';
import 'package:emc_helpline/l10n/app_localizations.dart';
import 'package:emc_helpline/models/report_enums.dart';
import 'package:emc_helpline/models/submission_outcome.dart';
import 'package:emc_helpline/providers/report_provider.dart';
import 'package:emc_helpline/views/reporting/report_landing_screen.dart';
import 'package:emc_helpline/views/reporting/reporting_wizard_screen.dart';
import 'package:emc_helpline/views/reporting/submission_error_screen.dart';

late SettingsStore _settings;

/// A transport that fails the first [failures] attempts, then succeeds.
/// Records every attempt so the tests can assert on what the server would see.
class _FlakySubmitter {
  _FlakySubmitter({
    required this.failures,
    this.failure = SubmissionFailure.network,
  });

  final int failures;
  final SubmissionFailure failure;
  final List<SubmissionAttempt> attempts = [];

  Future<String> call(SubmissionAttempt attempt) async {
    attempts.add(attempt);
    if (attempts.length <= failures) throw SubmissionException(failure);
    return 'EMC-4242-4242-4242';
  }
}

ReportProvider _completeProvider({ReportSubmitter? submitter}) {
  return ReportProvider(
    _settings,
    submissionLatency: Duration.zero,
    submitter: submitter,
  )..updateReport(
    whoFor: WhoFor.self,
    ageGroup: AgeGroup.teen,
    gender: Gender.undisclosed,
    incidentType: IncidentType.threat,
    platform: ReportPlatform.whatsapp,
    evidenceFilePaths: const ['/tmp/proof.png'],
    assistanceNeeded: AssistanceNeed.none,
    urgencyLevel: UrgencyLevel.notUrgent,
  );
}

Future<void> _pumpWizard(WidgetTester tester, ReportProvider provider) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<ReportProvider>.value(
      value: provider,
      child: const MaterialApp(
        // Pinned: the test binding otherwise resolves to English and every
        // French expectation below would miss for the wrong reason.
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportingWizardScreen(),
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

  group('failed submission', () {
    test('records the failure instead of throwing', () async {
      final provider = _completeProvider(
        submitter: _FlakySubmitter(failures: 1).call,
      );

      final code = await provider.submitReport();

      expect(code, isNull);
      expect(provider.submissionError, SubmissionFailure.network);
      expect(provider.failedAttempts, 1);
      expect(provider.isSubmitting, isFalse, reason: 'the spinner must stop');
      expect(provider.submittedRefCode, isNull);
      expect(provider.history, isEmpty);
    });

    test('keeps every answer so a retry costs nothing', () async {
      final provider = _completeProvider(
        submitter: _FlakySubmitter(failures: 1).call,
      );
      await provider.submitReport();

      expect(provider.currentReport.incidentType, IncidentType.threat);
      expect(provider.currentReport.evidenceFilePaths, ['/tmp/proof.png']);
      expect(provider.isReportComplete, isTrue);
    });

    test(
      'a transport throwing something unmapped still lands on a screen',
      () async {
        final provider = _completeProvider(
          submitter: (_) async => throw StateError('boom'),
        );

        await provider.submitReport();

        expect(provider.submissionError, SubmissionFailure.unknown);
      },
    );

    test('retrying succeeds and clears the error', () async {
      final submitter = _FlakySubmitter(failures: 1);
      final provider = _completeProvider(submitter: submitter.call);

      await provider.submitReport();
      final code = await provider.submitReport();

      expect(code, 'EMC-4242-4242-4242');
      expect(provider.submissionError, isNull);
      expect(provider.failedAttempts, 0);
      expect(provider.history, hasLength(1));
    });

    test('every retry carries the same idempotency key', () async {
      final submitter = _FlakySubmitter(failures: 2);
      final provider = _completeProvider(submitter: submitter.call);

      await provider.submitReport();
      await provider.submitReport();
      await provider.submitReport();

      expect(submitter.attempts, hasLength(3));
      final keys = submitter.attempts.map((a) => a.idempotencyKey).toSet();
      expect(
        keys,
        hasLength(1),
        reason: 'a retry after a timeout must not open a second case',
      );
    });

    test('a new report gets a new key', () async {
      final submitter = _FlakySubmitter(failures: 0);
      final provider = _completeProvider(submitter: submitter.call);

      await provider.submitReport();
      provider.startNewReport();
      provider.updateReport(
        whoFor: WhoFor.self,
        ageGroup: AgeGroup.teen,
        gender: Gender.undisclosed,
        incidentType: IncidentType.threat,
        platform: ReportPlatform.whatsapp,
        evidenceFilePaths: const ['/tmp/other.png'],
        assistanceNeeded: AssistanceNeed.none,
        urgencyLevel: UrgencyLevel.notUrgent,
      );
      await provider.submitReport();

      expect(
        submitter.attempts[0].idempotencyKey,
        isNot(submitter.attempts[1].idempotencyKey),
      );
    });

    test(
      'a timeout is reported as a timeout, not as a generic error',
      () async {
        final provider = _completeProvider(
          submitter: _FlakySubmitter(
            failures: 1,
            failure: SubmissionFailure.timeout,
          ).call,
        );

        await provider.submitReport();

        expect(provider.submissionError, SubmissionFailure.timeout);
      },
    );

    test('reviewing the report reopens the summary, error cleared', () async {
      final provider = _completeProvider(
        submitter: _FlakySubmitter(failures: 1).call,
      );
      await provider.submitReport();

      provider.dismissSubmissionError();

      expect(provider.submissionError, isNull);
      expect(provider.wizardStep, ReportProvider.stepSummary);
    });

    test('starting over wipes the failure with the answers', () async {
      final provider = _completeProvider(
        submitter: _FlakySubmitter(failures: 1).call,
      );
      await provider.submitReport();

      provider.startNewReport();

      expect(provider.submissionError, isNull);
      expect(provider.failedAttempts, 0);
      expect(provider.hasUnsentReport, isFalse);
    });
  });

  group('the screen the user lands on', () {
    testWidgets('replaces the form when the send fails', (tester) async {
      final provider = _completeProvider(
        submitter: _FlakySubmitter(failures: 1).call,
      );
      provider.startNewReport();
      provider.updateReport(
        whoFor: WhoFor.self,
        ageGroup: AgeGroup.teen,
        gender: Gender.undisclosed,
        incidentType: IncidentType.threat,
        platform: ReportPlatform.whatsapp,
        evidenceFilePaths: const ['/tmp/proof.png'],
        assistanceNeeded: AssistanceNeed.none,
        urgencyLevel: UrgencyLevel.notUrgent,
      );

      await _pumpWizard(tester, provider);
      await provider.submitReport();
      await tester.pumpAndSettle();

      expect(find.byType(SubmissionErrorScreen), findsOneWidget);
      // The promise that nothing was lost is what makes a retry thinkable.
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.submissionErrorAnswersKept), findsOneWidget);
      expect(find.text(l10n.submissionErrorRetry), findsOneWidget);
    });

    testWidgets('offers the direct line only once retrying stopped helping', (
      tester,
    ) async {
      final provider = _completeProvider(
        submitter: _FlakySubmitter(failures: 5).call,
      );
      provider.startNewReport();
      provider.updateReport(
        whoFor: WhoFor.self,
        ageGroup: AgeGroup.teen,
        gender: Gender.undisclosed,
        incidentType: IncidentType.threat,
        platform: ReportPlatform.whatsapp,
        evidenceFilePaths: const ['/tmp/proof.png'],
        assistanceNeeded: AssistanceNeed.none,
        urgencyLevel: UrgencyLevel.notUrgent,
      );
      await _pumpWizard(tester, provider);

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

      await provider.submitReport();
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.submissionErrorContactTeam),
        findsNothing,
        reason: 'one failure is not a reason to give up on the app',
      );

      await provider.submitReport();
      await tester.pumpAndSettle();
      expect(find.text(l10n.submissionErrorContactTeam), findsOneWidget);
      expect(find.text(l10n.submissionErrorCallPolice), findsOneWidget);
    });

    testWidgets('the landing offers to resume rather than silently discard', (
      tester,
    ) async {
      final provider = _completeProvider(
        submitter: _FlakySubmitter(failures: 1).call,
      );
      await provider.submitReport();
      provider.openReportLanding();

      await _pumpWizard(tester, provider);

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.byType(ReportLandingScreen), findsOneWidget);
      expect(find.text(l10n.reportLandingResume), findsOneWidget);

      await tester.tap(find.text(l10n.reportLandingResume));
      await tester.pumpAndSettle();

      expect(provider.wizardStep, ReportProvider.stepSummary);
      expect(provider.currentReport.incidentType, IncidentType.threat);
    });

    testWidgets('no resume card when nothing failed', (tester) async {
      final provider = _completeProvider();
      provider.openReportLanding();

      await _pumpWizard(tester, provider);

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.reportLandingResume), findsNothing);
    });
  });
}
