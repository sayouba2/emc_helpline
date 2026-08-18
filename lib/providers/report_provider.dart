import 'package:flutter/widgets.dart';
import '../core/storage/settings_store.dart';
import '../core/utils/reference_code.dart';
import '../core/utils/validators.dart';
import '../models/report_enums.dart';
import '../models/report_model.dart';
import '../models/submission_outcome.dart';

class ReportProvider with ChangeNotifier {
  ReportProvider(
    this._settings, {
    this.submissionLatency = const Duration(milliseconds: 1600),
    this.submitter,
  }) : _locale = _settings.readLocale();

  final SettingsStore _settings;

  /// How the report actually leaves the device. `null` uses the local
  /// simulation below — the backend passes its own implementation here, and
  /// tests pass one that throws.
  final ReportSubmitter? submitter;

  /// How long the simulated send takes, so the sending animation has something
  /// to cover. Unused once a real [ReportSubmitter] is injected. Tests pass
  /// [Duration.zero].
  final Duration submissionLatency;

  /// Wizard sub-step indices, in the same order as the step list built by
  /// `ReportingWizardScreen`. Kept here so the skip logic below and the screen
  /// can never drift apart again.
  static const int stepWho = 0;
  static const int stepAge = 1;
  static const int stepGender = 2;
  static const int stepIncidentType = 3;
  static const int stepPlatform = 4;
  static const int stepEvidence = 5;
  static const int stepAssistance = 6;
  static const int stepAssistanceType = 7;
  static const int stepContact = 8;
  static const int stepUrgency = 9;
  static const int stepSummary = 10;

  int _currentTab = 0;
  int _wizardStep = 0;
  Locale? _locale;
  String? _submittedRefCode;
  bool _isSubmitting = false;
  bool _isWizardOpen = false;
  SubmissionFailure? _submissionError;
  int _failedAttempts = 0;

  /// Identifies the report across retries — see [SubmissionAttempt]. Created on
  /// the first attempt and kept until that report is filed or abandoned, so a
  /// retry after a timeout cannot open a second case.
  String? _idempotencyKey;

  ReportModel _currentReport = const ReportModel();
  final List<ReportModel> _history = [];

  int get currentTab => _currentTab;
  int get wizardStep => _wizardStep;

  /// The language the user explicitly picked, or `null` to follow the device.
  /// `MaterialApp` resolves `null` against `supportedLocales`, falling back to
  /// French.
  Locale? get locale => _locale;
  ReportModel get currentReport => _currentReport;
  List<ReportModel> get history => List.unmodifiable(_history);

  /// Reference code of the report just submitted, or `null` while the wizard is
  /// still being filled in. Lives here rather than in the wizard's `State` so
  /// that [startNewReport] can clear it — the screen stays alive inside an
  /// `IndexedStack`, so widget-local state would strand the user on the success
  /// screen forever.
  String? get submittedRefCode => _submittedRefCode;

  /// True while the report is on its way. The wizard shows a sending screen.
  bool get isSubmitting => _isSubmitting;

  /// Why the last attempt failed, or `null` when nothing has failed. The wizard
  /// shows the error screen while this is set.
  SubmissionFailure? get submissionError => _submissionError;

  /// How many attempts in a row have failed. After the second, the error screen
  /// stops suggesting that retrying will help and offers the direct line
  /// instead — a child whose report is stuck should not be left pressing a
  /// button.
  int get failedAttempts => _failedAttempts;

  /// A complete report that failed to send and has not been abandoned.
  ///
  /// The landing screen offers to resume it, because [startNewReport] wipes the
  /// answers: without this, navigating away from the error screen and tapping
  /// "Faire un signalement" would silently discard everything the user wrote.
  bool get hasUnsentReport =>
      _submissionError != null && _idempotencyKey != null;

  /// Whether the report tab shows the form or its landing screen.
  ///
  /// Tapping the tab used to drop straight into an eleven-step form, which is
  /// a lot to commit to for someone who only wanted to check on an existing
  /// case. The landing offers both. The home call to action still opens the
  /// form directly — that path is for someone who has already decided.
  bool get isWizardOpen => _isWizardOpen;

  /// Only an explicit request for support opens the two follow-up questions.
  /// Declining and being unsure both leave the report anonymous: "I don't know"
  /// is not a request to be called back, nor an answer about what kind of help
  /// is needed.
  bool get _wantsAssistance =>
      _currentReport.assistanceNeeded == AssistanceNeed.wanted;

  /// Which steps the current answers make irrelevant.
  ///
  /// Navigation walks over this rather than jumping between hardcoded indices,
  /// so adding a conditional step cannot leave the forward and backward paths
  /// disagreeing — which is exactly how the skip logic broke before.
  bool _isStepSkipped(int step) => switch (step) {
    stepAssistanceType || stepContact => !_wantsAssistance,
    _ => false,
  };

  /// Why the current step cannot be left yet, or `null` when it is complete.
  ///
  /// The wizard uses this both to disable "next" and to tell the user what is
  /// still missing, so an empty report can no longer be submitted. It returns a
  /// key rather than a sentence: the provider has no `BuildContext`.
  ValidationMessage? get currentStepError {
    final report = _currentReport;
    switch (_wizardStep) {
      case stepWho:
        return report.whoFor == null ? ValidationMessage.chooseWho : null;
      case stepAge:
        return report.ageGroup == null ? ValidationMessage.chooseAge : null;
      case stepGender:
        return report.gender == null ? ValidationMessage.chooseGender : null;
      case stepIncidentType:
        return report.incidentType == null
            ? ValidationMessage.chooseIncident
            : null;
      case stepPlatform:
        return report.platform == null
            ? ValidationMessage.choosePlatform
            : null;
      case stepEvidence:
        return _evidenceStepError(report);
      case stepAssistance:
        return report.assistanceNeeded == null
            ? ValidationMessage.chooseAssistance
            : null;
      case stepAssistanceType:
        return report.assistanceType == null
            ? ValidationMessage.chooseAssistanceType
            : null;
      case stepContact:
        return _contactStepError(report);
      case stepUrgency:
        return report.urgencyLevel == null
            ? ValidationMessage.chooseUrgency
            : null;
      default:
        return null;
    }
  }

  /// A report has to carry something the team can look at: a screenshot, a
  /// link, or — when the user could keep none of it — an account of what
  /// happened, long enough to be worth reading.
  ValidationMessage? _evidenceStepError(ReportModel report) {
    final urlError = Validators.url(report.evidenceUrl);
    if (urlError != null) return urlError;
    if (report.hasEvidence) return null;
    if (Validators.isBlank(report.description)) {
      return ValidationMessage.missingEvidenceOrDescription;
    }
    if (!Validators.isDescriptionLongEnough(report.description)) {
      return ValidationMessage.descriptionTooShort;
    }
    return null;
  }

  /// Reached only by people who asked to be accompanied. A pseudonym and a
  /// phone number are all that is asked, and both are required — the team has
  /// no other way to call back.
  ValidationMessage? _contactStepError(ReportModel report) {
    if (Validators.isBlank(report.pseudo)) {
      return ValidationMessage.missingPseudo;
    }
    if (Validators.isBlank(report.contactPhone)) {
      return ValidationMessage.missingPhone;
    }
    return Validators.phone(report.contactPhone);
  }

  bool get canAdvance => currentStepError == null;

  /// Every answer the wizard requires, regardless of the step the user is on.
  ///
  /// [submitReport] checks this rather than just the current step, so jumping
  /// around with the summary's "Modifier" links can never produce a report with
  /// a hole in it.
  bool get isReportComplete {
    final report = _currentReport;
    final hasEveryChoice =
        report.whoFor != null &&
        report.ageGroup != null &&
        report.gender != null &&
        report.incidentType != null &&
        report.platform != null &&
        report.assistanceNeeded != null &&
        report.urgencyLevel != null;
    if (!hasEveryChoice) return false;

    if (_evidenceStepError(report) != null) return false;

    // A skipped step can never be required.
    if (!_wantsAssistance) return true;
    if (report.assistanceType == null) return false;
    if (_contactStepError(report) != null) return false;

    return true;
  }

  void setTab(int tabIndex) {
    _currentTab = tabIndex;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
    // Fire and forget: the UI must not wait on the disk write.
    _settings.writeLocale(locale);
  }

  void setWizardStep(int step) {
    _wizardStep = step.clamp(stepWho, stepSummary);
    notifyListeners();
  }

  void nextWizardStep() {
    if (!canAdvance) return;
    var next = _wizardStep;
    do {
      next++;
    } while (next < stepSummary && _isStepSkipped(next));
    _wizardStep = next.clamp(stepWho, stepSummary);
    notifyListeners();
  }

  void previousWizardStep() {
    var previous = _wizardStep;
    do {
      previous--;
    } while (previous > stepWho && _isStepSkipped(previous));
    _wizardStep = previous.clamp(stepWho, stepSummary);
    notifyListeners();
  }

  /// Shows the report tab's landing screen, leaving any answers untouched.
  void openReportLanding() {
    _isWizardOpen = false;
    _currentTab = 1;
    _submittedRefCode = null;
    notifyListeners();
  }

  void startNewReport() {
    _isWizardOpen = true;
    _isSubmitting = false;
    _currentReport = const ReportModel();
    _wizardStep = stepWho;
    _currentTab = 1;
    _submittedRefCode = null;
    _clearSubmissionState();
    notifyListeners();
  }

  /// Reopens the summary of a report whose send failed, answers intact.
  void resumeUnsentReport() {
    _isWizardOpen = true;
    _currentTab = 1;
    _wizardStep = stepSummary;
    _submissionError = null;
    notifyListeners();
  }

  /// Leaves the error screen for the summary, so the user can check or change
  /// an answer before trying again. The idempotency key survives: it is still
  /// the same report.
  void dismissSubmissionError() {
    if (_submissionError == null) return;
    _submissionError = null;
    _wizardStep = stepSummary;
    notifyListeners();
  }

  void _clearSubmissionState() {
    _submissionError = null;
    _failedAttempts = 0;
    _idempotencyKey = null;
  }

  /// The enum-typed arguments can only be set, never cleared. The free-text
  /// ones default to [unsetField]: omit them to keep the current value, pass
  /// `null` to clear (see [ReportModel.copyWith]).
  void updateReport({
    WhoFor? whoFor,
    Object? pseudo = unsetField,
    AgeGroup? ageGroup,
    Gender? gender,
    IncidentType? incidentType,
    ReportPlatform? platform,
    List<String>? evidenceFilePaths,
    Object? evidenceUrl = unsetField,
    Object? description = unsetField,
    AssistanceNeed? assistanceNeeded,
    AssistanceType? assistanceType,
    UrgencyLevel? urgencyLevel,
    Object? contactPhone = unsetField,
  }) {
    _currentReport = _currentReport.copyWith(
      whoFor: whoFor,
      pseudo: pseudo,
      ageGroup: ageGroup,
      gender: gender,
      incidentType: incidentType,
      platform: platform,
      evidenceFilePaths: evidenceFilePaths,
      evidenceUrl: evidenceUrl,
      description: description,
      assistanceNeeded: assistanceNeeded,
      assistanceType: assistanceType,
      urgencyLevel: urgencyLevel,
      contactPhone: contactPhone,
    );
    notifyListeners();
  }

  /// Sends the report, or records why it could not be sent.
  ///
  /// Never throws: a failure becomes [submissionError], which the wizard turns
  /// into the error screen. Calling it again is the retry — the answers are
  /// untouched and the attempt carries the same [_idempotencyKey].
  Future<String?> submitReport() async {
    if (!isReportComplete || _isSubmitting) return null;

    _isSubmitting = true;
    _submissionError = null;
    _idempotencyKey ??= _newIdempotencyKey();
    notifyListeners();

    try {
      final send = submitter ?? _simulateSubmission;
      final code = await send((
        report: _currentReport,
        idempotencyKey: _idempotencyKey!,
      ));

      _currentReport = _currentReport.copyWith(
        referenceCode: code,
        createdAt: DateTime.now(),
      );
      _history.insert(0, _currentReport);
      _submittedRefCode = code;
      _clearSubmissionState();
      return code;
    } on SubmissionException catch (error) {
      _submissionError = error.failure;
      _failedAttempts++;
      return null;
    } catch (_) {
      // A transport that throws something else is a bug, but the user still
      // gets a screen they can act on rather than a frozen animation.
      _submissionError = SubmissionFailure.unknown;
      _failedAttempts++;
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Stands in for the server until the backend exists. It always succeeds —
  /// the failure paths are exercised by injecting a [ReportSubmitter].
  Future<String> _simulateSubmission(SubmissionAttempt attempt) async {
    await Future<void>.delayed(submissionLatency);
    return ReferenceCode.generate();
  }

  /// Unique enough to deduplicate retries of one report; the server is what
  /// enforces it, this only has to stay stable across attempts.
  String _newIdempotencyKey() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}'
      '-${ReferenceCode.generate()}';

  /// Adds screenshots to the evidence, ignoring the ones already attached so a
  /// second pass through the picker cannot duplicate them.
  void addEvidenceFiles(Iterable<String> paths) {
    final merged = <String>[
      ..._currentReport.evidenceFilePaths,
      ...paths.where((p) => !_currentReport.evidenceFilePaths.contains(p)),
    ];
    updateReport(evidenceFilePaths: merged);
  }

  void removeEvidenceFile(String path) {
    updateReport(
      evidenceFilePaths: _currentReport.evidenceFilePaths
          .where((p) => p != path)
          .toList(growable: false),
    );
  }

  /// Looks a report up by the reference code handed to the user.
  ///
  /// Backed by this session's history for now; it becomes a server lookup once
  /// the backend exists.
  /// The comparison goes through [ReferenceCode.payloadOf] on both sides, so
  /// what the user typed is matched by what it means, not by how it looks:
  /// lower case, missing dashes and an `O` typed for a `0` all still find the
  /// case.
  ReportModel? findByReference(String code) {
    final needle = ReferenceCode.payloadOf(code);
    if (needle == null) return null;
    for (final report in _history) {
      if (ReferenceCode.payloadOf(report.referenceCode) == needle) {
        return report;
      }
    }
    return null;
  }
}
