import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emc_helpline/core/storage/settings_store.dart';
import 'package:emc_helpline/core/localization/report_enum_labels.dart';
import 'package:emc_helpline/l10n/app_localizations.dart';
import 'package:emc_helpline/main.dart';
import 'package:emc_helpline/models/report_enums.dart';
import 'package:emc_helpline/providers/report_provider.dart';
import 'package:emc_helpline/views/components/choice_card.dart';
import 'package:emc_helpline/views/reporting/reporting_wizard_screen.dart';
import 'package:emc_helpline/views/splash_screen.dart';

/// Nothing exercised the eleven step screens before: the tab bar builds only
/// the visible tab, so pumping the app never reached them. A redesign could
/// therefore break every step while the suite stayed green.
Future<ReportProvider> _openWizard(
  WidgetTester tester, {
  double textScale = 1.0,
  Size size = const Size(390, 844),
  bool fillAnswers = true,
}) async {
  SharedPreferences.setMockInitialValues({'settings.localeLanguageCode': 'fr'});
  final settings = await SettingsStore.open();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(
        tester.view,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: EMCHelplineApp(settings: settings),
    ),
  );
  await tester.pump();
  await tester.pump(SplashGate.total);
  await tester.pump(const Duration(milliseconds: 600));

  final provider = Provider.of<ReportProvider>(
    tester.element(find.byType(MaterialApp)),
    listen: false,
  );
  provider.setTab(1);
  if (fillAnswers) {
    provider.updateReport(
      whoFor: WhoFor.self,
      ageGroup: AgeGroup.teen,
      gender: Gender.female,
      incidentType: IncidentType.threat,
      platform: ReportPlatform.whatsapp,
      assistanceNeeded: AssistanceNeed.wanted,
      assistanceType: AssistanceType.legal,
      urgencyLevel: UrgencyLevel.urgent,
      pseudo: 'HérosDiscret42',
      contactPhone: '0612345678',
      description: 'a' * 200,
    );
  }
  await tester.pump(const Duration(milliseconds: 600));
  return provider;
}

Future<void> _showStep(WidgetTester tester, ReportProvider p, int step) async {
  p.setWizardStep(step);
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('every step lays out', () {
    for (final scale in <double>[1.0, 2.0]) {
      testWidgets('at ${scale}x text', (tester) async {
        final provider = await _openWizard(tester, textScale: scale);

        for (
          var step = ReportProvider.stepWho;
          step <= ReportProvider.stepSummary;
          step++
        ) {
          await _showStep(tester, provider, step);
          expect(
            tester.takeException(),
            isNull,
            reason: 'step $step overflowed at ${scale}x',
          );
          expect(find.byType(ReportingWizardScreen), findsOneWidget);
        }
      });
    }

    testWidgets('in landscape', (tester) async {
      final provider = await _openWizard(tester, size: const Size(844, 390));

      for (
        var step = ReportProvider.stepWho;
        step <= ReportProvider.stepSummary;
        step++
      ) {
        await _showStep(tester, provider, step);
        expect(
          tester.takeException(),
          isNull,
          reason: 'step $step in landscape',
        );
      }
    });

    testWidgets('with nothing answered yet', (tester) async {
      final provider = await _openWizard(tester, fillAnswers: false);

      // An empty report is the state a real user starts in.
      for (
        var step = ReportProvider.stepWho;
        step <= ReportProvider.stepSummary;
        step++
      ) {
        await _showStep(tester, provider, step);
        expect(tester.takeException(), isNull, reason: 'empty step $step');
      }
    });
  });

  testWidgets('a choice can be made and reaches the report', (tester) async {
    final provider = await _openWizard(tester, fillAnswers: false);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    await _showStep(tester, provider, ReportProvider.stepGender);
    expect(provider.currentReport.gender, isNull);

    await tester.tap(find.text(Gender.female.label(l10n)));
    await tester.pump();

    expect(provider.currentReport.gender, Gender.female);
  });

  testWidgets('the chosen option is announced as selected', (tester) async {
    final handle = tester.ensureSemantics();
    final provider = await _openWizard(tester, fillAnswers: false);

    await _showStep(tester, provider, ReportProvider.stepGender);
    provider.updateReport(gender: Gender.male);
    await tester.pump(const Duration(milliseconds: 400));

    final selected = tester
        .widgetList<ChoiceCard>(find.byType(ChoiceCard))
        .where((card) => card.isSelected);
    expect(
      selected.length,
      1,
      reason: 'exactly one answer carries the selected state',
    );

    handle.dispose();
  });

  testWidgets('the progress bar advances at every step, not every phase', (
    tester,
  ) async {
    final provider = await _openWizard(tester);

    double barValue() => tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;

    await _showStep(tester, provider, ReportProvider.stepIncidentType);
    final atIncident = barValue();
    await _showStep(tester, provider, ReportProvider.stepPlatform);
    final atPlatform = barValue();

    // Both sit in phase 3, where the bar used to stand still for seven steps.
    expect(atPlatform, greaterThan(atIncident));
  });
}
