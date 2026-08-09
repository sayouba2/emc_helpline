import 'dart:math';
import 'package:flutter/widgets.dart';
import '../core/storage/settings_store.dart';
import '../core/utils/validators.dart';
import '../models/report_enums.dart';
import '../models/report_model.dart';

class ReportProvider with ChangeNotifier {
  ReportProvider(this._settings) : _locale = _settings.readLocale();

  final SettingsStore _settings;

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

  bool get _skipsAssistanceType =>
      _currentReport.assistanceNeeded == AssistanceNeed.none;

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
        if (!report.hasEvidenceAnswer) return ValidationMessage.chooseEvidence;
        return Validators.url(report.evidenceUrl);
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

  ValidationMessage? _contactStepError(ReportModel report) {
    if (report.isAnonymous) return null;
    if (!report.hasAnyContactDetail) return ValidationMessage.missingContact;
    return Validators.phone(report.contactPhone) ??
        Validators.phone(report.contactWhatsapp) ??
        Validators.email(report.contactEmail);
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

    final needsAssistanceType = report.assistanceNeeded != AssistanceNeed.none;
    if (needsAssistanceType && report.assistanceType == null) return false;

    if (!report.hasEvidenceAnswer) return false;

    return Validators.url(report.evidenceUrl) == null &&
        _contactStepError(report) == null;
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
    if (_wizardStep == stepAssistance && _skipsAssistanceType) {
      _wizardStep = stepContact;
    } else if (_wizardStep < stepSummary) {
      _wizardStep++;
    }
    notifyListeners();
  }

  void previousWizardStep() {
    if (_wizardStep == stepContact && _skipsAssistanceType) {
      _wizardStep = stepAssistance;
    } else if (_wizardStep > stepWho) {
      _wizardStep--;
    }
    notifyListeners();
  }

  void startNewReport() {
    _currentReport = const ReportModel();
    _wizardStep = stepWho;
    _currentTab = 1;
    _submittedRefCode = null;
    notifyListeners();
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
    Object? evidenceFilePath = unsetField,
    Object? evidenceUrl = unsetField,
    bool? hasNoEvidence,
    AssistanceNeed? assistanceNeeded,
    AssistanceType? assistanceType,
    UrgencyLevel? urgencyLevel,
    bool? isAnonymous,
    Object? contactPhone = unsetField,
    Object? contactEmail = unsetField,
    Object? contactWhatsapp = unsetField,
  }) {
    _currentReport = _currentReport.copyWith(
      whoFor: whoFor,
      pseudo: pseudo,
      ageGroup: ageGroup,
      gender: gender,
      incidentType: incidentType,
      platform: platform,
      evidenceFilePath: evidenceFilePath,
      evidenceUrl: evidenceUrl,
      hasNoEvidence: hasNoEvidence,
      assistanceNeeded: assistanceNeeded,
      assistanceType: assistanceType,
      urgencyLevel: urgencyLevel,
      isAnonymous: isAnonymous,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      contactWhatsapp: contactWhatsapp,
    );
    notifyListeners();
  }

  String? submitReport() {
    if (!isReportComplete) return null;

    final randNum = Random().nextInt(900000) + 100000;
    final code = "REF-EMC-2026-$randNum";

    _currentReport = _currentReport.copyWith(
      referenceCode: code,
      createdAt: DateTime.now(),
    );

    _history.insert(0, _currentReport);
    _submittedRefCode = code;
    notifyListeners();
    return code;
  }
}
