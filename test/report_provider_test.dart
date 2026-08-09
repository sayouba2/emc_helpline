import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emc_helpline/core/storage/settings_store.dart';
import 'package:emc_helpline/models/report_enums.dart';
import 'package:emc_helpline/providers/report_provider.dart';

/// The provider only touches storage for preferences, so an empty in-memory
/// store is enough for every test here.
late SettingsStore _settings;

ReportProvider _provider() =>
    ReportProvider(_settings, submissionLatency: Duration.zero);

/// Fills in every answer the wizard requires, so navigation tests are not
/// blocked by the step validation.
ReportProvider _completeProvider() {
  return _provider()..updateReport(
    whoFor: WhoFor.self,
    ageGroup: AgeGroup.teen,
    gender: Gender.undisclosed,
    incidentType: IncidentType.threat,
    platform: ReportPlatform.whatsapp,
    evidenceFilePaths: const ['/tmp/proof.png'],
    assistanceNeeded: AssistanceNeed.wanted,
    assistanceType: AssistanceType.legal,
    urgencyLevel: UrgencyLevel.notUrgent,
    pseudo: 'HérosDiscret42',
    contactPhone: '0612345678',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _settings = await SettingsStore.open();
  });

  group('submittedRefCode lifecycle', () {
    test('is null until a report is submitted', () {
      expect(_provider().submittedRefCode, isNull);
    });

    test('is exposed after submitReport', () async {
      final provider = _completeProvider();
      final code = await provider.submitReport();
      expect(provider.submittedRefCode, code);
      expect(provider.history, hasLength(1));
    });

    test('startNewReport clears it so a second report is possible', () async {
      final provider = _completeProvider();
      await provider.submitReport();

      provider.startNewReport();

      expect(provider.submittedRefCode, isNull);
      expect(provider.wizardStep, ReportProvider.stepWho);
      expect(provider.currentReport.whoFor, isNull);
      expect(provider.history, hasLength(1), reason: 'history is kept');
    });
  });

  group('updateReport null handling', () {
    test('omitting an argument keeps the current value', () {
      final provider = _provider();
      provider.updateReport(contactPhone: '0612345678');

      provider.updateReport(pseudo: 'ÉtoileSecrète99');

      expect(provider.currentReport.contactPhone, '0612345678');
      expect(provider.currentReport.pseudo, 'ÉtoileSecrète99');
    });

    test('passing null clears the contact details', () {
      final provider = _provider();
      provider.updateReport(
        pseudo: 'HérosDiscret42',
        contactPhone: '0612345678',
      );
      expect(provider.currentReport.isAnonymous, isFalse);

      provider.updateReport(pseudo: null, contactPhone: null);

      expect(provider.currentReport.pseudo, isNull);
      expect(provider.currentReport.contactPhone, isNull);
      expect(
        provider.currentReport.isAnonymous,
        isTrue,
        reason: 'anonymity is derived from the absence of a phone number',
      );
    });

    test('screenshots accumulate and can be removed one by one', () {
      final provider = _provider();

      provider.addEvidenceFiles(['/tmp/a.png', '/tmp/b.png']);
      provider.addEvidenceFiles(['/tmp/b.png', '/tmp/c.png']);
      expect(
        provider.currentReport.evidenceFilePaths,
        ['/tmp/a.png', '/tmp/b.png', '/tmp/c.png'],
        reason: 'a second pass through the picker must not duplicate',
      );

      provider.removeEvidenceFile('/tmp/b.png');
      expect(provider.currentReport.evidenceFilePaths, [
        '/tmp/a.png',
        '/tmp/c.png',
      ]);
    });
  });

  group('wizard navigation', () {
    test('advances one step at a time by default', () {
      final provider = _completeProvider();
      provider.nextWizardStep();
      expect(provider.wizardStep, ReportProvider.stepAge);
    });

    test('shows the assistance type step when assistance is wanted', () {
      final provider = _completeProvider();
      provider.setWizardStep(ReportProvider.stepAssistance);
      provider.updateReport(assistanceNeeded: AssistanceNeed.wanted);

      provider.nextWizardStep();

      expect(provider.wizardStep, ReportProvider.stepAssistanceType);
    });

    test('declining support skips both the type and the contact steps', () {
      final provider = _completeProvider();
      provider.setWizardStep(ReportProvider.stepAssistance);
      provider.updateReport(assistanceNeeded: AssistanceNeed.none);

      provider.nextWizardStep();

      expect(
        provider.wizardStep,
        ReportProvider.stepUrgency,
        reason: 'nobody who declined help is asked how to reach them',
      );
    });

    test('being unsure skips the type and the contact steps too', () {
      final provider = _completeProvider();
      provider.setWizardStep(ReportProvider.stepAssistance);
      provider.updateReport(assistanceNeeded: AssistanceNeed.unsure);

      provider.nextWizardStep();
      expect(
        provider.wizardStep,
        ReportProvider.stepUrgency,
        reason: '"I don\'t know" is neither an answer nor a call-back request',
      );

      provider.previousWizardStep();
      expect(provider.wizardStep, ReportProvider.stepAssistance);
    });

    test('skips them backwards too, symmetrically', () {
      final provider = _completeProvider();
      provider.updateReport(assistanceNeeded: AssistanceNeed.none);
      provider.setWizardStep(ReportProvider.stepUrgency);

      provider.previousWizardStep();

      expect(provider.wizardStep, ReportProvider.stepAssistance);
    });

    test('does not skip the evidence step (regression: off-by-one)', () {
      final provider = _completeProvider();
      provider.updateReport(assistanceNeeded: AssistanceNeed.none);
      provider.setWizardStep(ReportProvider.stepEvidence);

      provider.nextWizardStep();

      expect(provider.wizardStep, ReportProvider.stepAssistance);
    });

    test('never runs past the summary or before the first step', () {
      final provider = _completeProvider();
      provider.setWizardStep(ReportProvider.stepSummary);
      provider.nextWizardStep();
      expect(provider.wizardStep, ReportProvider.stepSummary);

      provider.setWizardStep(ReportProvider.stepWho);
      provider.previousWizardStep();
      expect(provider.wizardStep, ReportProvider.stepWho);
    });
  });

  group('step validation', () {
    test('a fresh report cannot leave the first step', () {
      final provider = _provider();

      expect(provider.canAdvance, isFalse);
      expect(provider.currentStepError, isNotNull);

      provider.nextWizardStep();
      expect(
        provider.wizardStep,
        ReportProvider.stepWho,
        reason: 'nextWizardStep must be a no-op while invalid',
      );
    });

    test('answering the question unblocks the step', () {
      final provider = _provider();
      provider.updateReport(whoFor: WhoFor.self);

      expect(provider.canAdvance, isTrue);
      provider.nextWizardStep();
      expect(provider.wizardStep, ReportProvider.stepAge);
    });

    test('going backwards is never blocked by validation', () {
      final provider = _provider();
      provider.setWizardStep(ReportProvider.stepGender);

      provider.previousWizardStep();

      expect(provider.wizardStep, ReportProvider.stepAge);
    });

    test('the evidence step requires a screenshot or a link', () {
      final provider = _completeProvider();
      provider.updateReport(evidenceFilePaths: const [], evidenceUrl: null);
      provider.setWizardStep(ReportProvider.stepEvidence);
      expect(
        provider.canAdvance,
        isFalse,
        reason: 'an anonymous report with nothing to look at cannot be triaged',
      );

      provider.addEvidenceFiles(['/tmp/proof.png']);
      expect(provider.canAdvance, isTrue);

      provider.removeEvidenceFile('/tmp/proof.png');
      expect(provider.canAdvance, isFalse);

      provider.updateReport(evidenceUrl: 'exemple.com/post/1');
      expect(provider.canAdvance, isTrue, reason: 'a link alone is enough');
    });

    test('the evidence step rejects a malformed link', () {
      final provider = _completeProvider();
      provider.setWizardStep(ReportProvider.stepEvidence);
      provider.updateReport(evidenceUrl: 'pas-un-lien');

      expect(provider.canAdvance, isFalse);

      provider.updateReport(evidenceUrl: 'exemple.com/post/1');
      expect(provider.canAdvance, isTrue);
    });

    test('the contact step requires a pseudonym and a phone number', () {
      final provider = _completeProvider();
      provider.setWizardStep(ReportProvider.stepContact);
      expect(provider.canAdvance, isTrue);

      provider.updateReport(pseudo: '  ');
      expect(
        provider.canAdvance,
        isFalse,
        reason: 'the team calls back using the pseudonym',
      );

      provider.updateReport(pseudo: 'ÉtoileSecrète99', contactPhone: '');
      expect(provider.canAdvance, isFalse);

      provider.updateReport(contactPhone: '0612345678');
      expect(provider.canAdvance, isTrue);
    });

    test('the contact step rejects a malformed phone number', () {
      final provider = _completeProvider();
      provider.setWizardStep(ReportProvider.stepContact);

      provider.updateReport(contactPhone: '123');
      expect(provider.canAdvance, isFalse);

      provider.updateReport(contactPhone: '0612345678');
      expect(provider.canAdvance, isTrue);
    });

    test('an unsure report is complete without contact details', () {
      final provider = _provider()
        ..updateReport(
          whoFor: WhoFor.self,
          ageGroup: AgeGroup.adult,
          gender: Gender.male,
          incidentType: IncidentType.defamation,
          platform: ReportPlatform.facebook,
          evidenceFilePaths: const ['/tmp/proof.png'],
          assistanceNeeded: AssistanceNeed.unsure,
          assistanceType: AssistanceType.unsure,
          urgencyLevel: UrgencyLevel.unsure,
        );

      expect(provider.currentReport.isAnonymous, isTrue);
      expect(provider.isReportComplete, isTrue);
    });

    test('a report that declines support needs no contact details', () {
      final provider = _provider()
        ..updateReport(
          whoFor: WhoFor.someoneElse,
          ageGroup: AgeGroup.child,
          gender: Gender.female,
          incidentType: IncidentType.hateSpeech,
          platform: ReportPlatform.tiktok,
          evidenceFilePaths: const ['/tmp/proof.png'],
          assistanceNeeded: AssistanceNeed.none,
          urgencyLevel: UrgencyLevel.urgent,
        );

      expect(provider.currentReport.pseudo, isNull);
      expect(provider.currentReport.isAnonymous, isTrue);
      expect(provider.isReportComplete, isTrue);
    });

    test('an incomplete report cannot be submitted from the summary', () async {
      final provider = _provider();
      // The summary step asks no question of its own, so being on it is not
      // enough — the whole report has to hold together.
      provider.setWizardStep(ReportProvider.stepSummary);

      expect(provider.canAdvance, isTrue);
      expect(provider.isReportComplete, isFalse);
      expect(await provider.submitReport(), isNull);
      expect(provider.history, isEmpty);
      expect(provider.submittedRefCode, isNull);
    });

    test('a report missing only its assistance type is rejected', () {
      final provider = _completeProvider();
      expect(provider.isReportComplete, isTrue);

      provider.startNewReport();
      provider.updateReport(
        whoFor: WhoFor.self,
        ageGroup: AgeGroup.teen,
        gender: Gender.undisclosed,
        incidentType: IncidentType.threat,
        platform: ReportPlatform.whatsapp,
        evidenceFilePaths: const ['/tmp/proof.png'],
        assistanceNeeded: AssistanceNeed.wanted,
        urgencyLevel: UrgencyLevel.notUrgent,
      );

      expect(provider.isReportComplete, isFalse);
    });

    test('no assistance means no assistance type is required', () {
      final provider = _completeProvider();
      provider.startNewReport();
      provider.updateReport(
        whoFor: WhoFor.self,
        ageGroup: AgeGroup.child,
        gender: Gender.female,
        incidentType: IncidentType.hateSpeech,
        platform: ReportPlatform.tiktok,
        evidenceFilePaths: const ['/tmp/proof.png'],
        assistanceNeeded: AssistanceNeed.none,
        urgencyLevel: UrgencyLevel.urgent,
      );

      expect(provider.isReportComplete, isTrue);
    });
  });

  group('submission feedback', () {
    test('isSubmitting is raised while the report is on its way', () async {
      final provider =
          ReportProvider(
            _settings,
            submissionLatency: const Duration(milliseconds: 40),
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

      final pending = provider.submitReport();
      expect(
        provider.isSubmitting,
        isTrue,
        reason: 'the sending screen is shown off this flag',
      );

      await pending;
      expect(provider.isSubmitting, isFalse);
      expect(provider.submittedRefCode, isNotNull);
    });

    test('a second tap while sending is ignored', () async {
      final provider = _completeProvider();

      final first = provider.submitReport();
      final second = await provider.submitReport();
      await first;

      expect(second, isNull);
      expect(provider.history, hasLength(1));
    });
  });

  group('tracking a request', () {
    test('finds a submitted report by its reference code', () async {
      final provider = _completeProvider();
      final code = await provider.submitReport();

      expect(provider.findByReference(code!), isNotNull);
      expect(
        provider.findByReference(code.toLowerCase()),
        isNotNull,
        reason: 'the code is typed by hand, so case must not matter',
      );
      expect(provider.findByReference('  $code  '), isNotNull);
    });

    test('returns null for an unknown or empty code', () async {
      final provider = _completeProvider();
      await provider.submitReport();

      expect(provider.findByReference('REF-EMC-2026-000000'), isNull);
      expect(provider.findByReference(''), isNull);
      expect(provider.findByReference('   '), isNull);
    });
  });
}
