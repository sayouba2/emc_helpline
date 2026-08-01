import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/report_model.dart';

class ReportProvider with ChangeNotifier {
  int _currentTab = 0;
  int _wizardStep = 0; // 0..7
  bool _isPanicMode = false;
  String _currentLanguage = 'fr';

  ReportModel _currentReport = ReportModel();
  final List<ReportModel> _history = [];

  int get currentTab => _currentTab;
  int get wizardStep => _wizardStep;
  bool get isPanicMode => _isPanicMode;
  String get currentLanguage => _currentLanguage;
  ReportModel get currentReport => _currentReport;
  List<ReportModel> get history => List.unmodifiable(_history);

  void setTab(int tabIndex) {
    _currentTab = tabIndex;
    notifyListeners();
  }

  void togglePanicMode() {
    _isPanicMode = !_isPanicMode;
    notifyListeners();
  }

  void setLanguage(String langCode) {
    _currentLanguage = langCode;
    notifyListeners();
  }

  void setWizardStep(int step) {
    _wizardStep = step;
    notifyListeners();
  }

  void nextWizardStep() {
    // Logic for conditional skipping:
    // Step 0: WhoFor
    // Step 1: AgeRange
    // Step 2: Gender
    // Step 3: IncidentType & Platform
    // Step 4: Evidence
    // Step 5: Assistance (If "Pas d'accompagnement", jump over Step 6 AssistanceType)
    // Step 6: AssistanceType
    // Step 7: Contact Info
    // Step 8: Urgency
    // Step 9: Summary

    if (_wizardStep == 5 && _currentReport.wantsAssistance == "Pas d'accompagnement") {
      _wizardStep = 7; // Skip assistance type step
    } else {
      _wizardStep++;
    }
    notifyListeners();
  }

  void previousWizardStep() {
    if (_wizardStep == 7 && _currentReport.wantsAssistance == "Pas d'accompagnement") {
      _wizardStep = 5;
    } else if (_wizardStep > 0) {
      _wizardStep--;
    }
    notifyListeners();
  }

  void startNewReport() {
    _currentReport = ReportModel();
    _wizardStep = 0;
    _currentTab = 1;
    notifyListeners();
  }

  void updateReport({
    String? whoFor,
    String? ageRange,
    String? gender,
    String? incidentType,
    String? platform,
    String? evidenceImagePath,
    String? evidenceUrl,
    bool? hasNoEvidence,
    String? wantsAssistance,
    String? assistanceType,
    String? urgency,
    bool? isAnonymous,
    String? contactPhone,
    String? contactEmail,
    String? contactWhatsapp,
  }) {
    _currentReport = _currentReport.copyWith(
      whoFor: whoFor,
      ageRange: ageRange,
      gender: gender,
      incidentType: incidentType,
      platform: platform,
      evidenceImagePath: evidenceImagePath,
      evidenceUrl: evidenceUrl,
      hasNoEvidence: hasNoEvidence,
      wantsAssistance: wantsAssistance,
      assistanceType: assistanceType,
      urgency: urgency,
      isAnonymous: isAnonymous,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      contactWhatsapp: contactWhatsapp,
    );
    notifyListeners();
  }

  String submitReport() {
    final randNum = Random().nextInt(900000) + 100000;
    final code = "REF-EMC-2026-$randNum";

    _currentReport = _currentReport.copyWith(
      referenceCode: code,
      createdAt: DateTime.now(),
    );

    _history.insert(0, _currentReport);
    notifyListeners();
    return code;
  }
}
