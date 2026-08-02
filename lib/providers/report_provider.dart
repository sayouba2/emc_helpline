import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/report_model.dart';

class ReportProvider with ChangeNotifier {
  int _currentTab = 0;
  int _wizardStep = 0;
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
    if (_wizardStep == 5 && _currentReport.assistanceNeeded == "Pas d'accompagnement") {
      _wizardStep = 7; // Skip assistance type step
    } else {
      _wizardStep++;
    }
    notifyListeners();
  }

  void previousWizardStep() {
    if (_wizardStep == 7 && _currentReport.assistanceNeeded == "Pas d'accompagnement") {
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
    String? pseudo,
    String? ageGroup,
    String? ageRange,
    String? gender,
    String? incidentType,
    String? platform,
    String? evidenceFilePath,
    String? evidenceImagePath,
    String? evidenceUrl,
    bool? hasNoEvidence,
    String? assistanceNeeded,
    String? wantsAssistance,
    String? assistanceType,
    String? urgencyLevel,
    String? urgency,
    bool? isAnonymous,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? contactWhatsapp,
  }) {
    _currentReport = _currentReport.copyWith(
      whoFor: whoFor,
      pseudo: pseudo,
      ageGroup: ageGroup,
      ageRange: ageRange,
      gender: gender,
      incidentType: incidentType,
      platform: platform,
      evidenceFilePath: evidenceFilePath,
      evidenceImagePath: evidenceImagePath,
      evidenceUrl: evidenceUrl,
      hasNoEvidence: hasNoEvidence,
      assistanceNeeded: assistanceNeeded,
      wantsAssistance: wantsAssistance,
      assistanceType: assistanceType,
      urgencyLevel: urgencyLevel,
      urgency: urgency,
      isAnonymous: isAnonymous,
      contactName: contactName,
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
