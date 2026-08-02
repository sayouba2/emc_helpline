import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/app_translations.dart';
import '../../providers/report_provider.dart';
import '../../providers/theme_provider.dart';
import '../components/animated_indexed_stack.dart';
import '../components/stepper_widget.dart';
import 'report_success_screen.dart';
import 'steps/step1_who_screen.dart';
import 'steps/step2_age_screen.dart';
import 'steps/step2_gender_screen.dart';
import 'steps/step3_incident_type_screen.dart';
import 'steps/step3_platform_screen.dart';
import 'steps/step3_evidence_screen.dart';
import 'steps/step3_assistance_screen.dart';
import 'steps/step3_assistance_type_screen.dart';
import 'steps/step3_contact_screen.dart';
import 'steps/step3_urgency_screen.dart';
import 'steps/step4_summary_screen.dart';

class ReportingWizardScreen extends StatefulWidget {
  const ReportingWizardScreen({super.key});

  @override
  State<ReportingWizardScreen> createState() => _ReportingWizardScreenState();
}

class _ReportingWizardScreenState extends State<ReportingWizardScreen> {
  String? _submittedRefCode;

  int _getStepperNumber(int subStep) {
    if (subStep == 0) return 1;
    if (subStep == 1 || subStep == 2) return 2;
    if (subStep >= 3 && subStep <= 9) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final lang = reportProvider.currentLanguage;

    if (_submittedRefCode != null) {
      return ReportSuccessScreen(referenceCode: _submittedRefCode!);
    }

    final subStep = reportProvider.wizardStep;
    final stepperNumber = _getStepperNumber(subStep);
    final isLastStep = subStep == 10;

    final List<Widget> stepWidgets = [
      const Step1WhoScreen(),
      const Step2AgeScreen(),
      const Step2GenderScreen(),
      const Step3IncidentTypeScreen(),
      const Step3PlatformScreen(),
      const Step3EvidenceScreen(),
      const Step3AssistanceScreen(),
      const Step3AssistanceTypeScreen(),
      const Step3ContactScreen(),
      const Step3UrgencyScreen(),
      const Step4SummaryScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: Column(
        children: [
          // Stepper bar
          StepperWidget(currentStep: stepperNumber),
          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),

          // Current Step Content with AnimatedIndexedStack
          Expanded(
            child: AnimatedIndexedStack(
              index: subStep.clamp(0, stepWidgets.length - 1),
              children: stepWidgets,
            ),
          ),

          // Bottom Action Bar (Direct buttons without enclosing card)
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 74, top: 4),
            child: SafeArea(
              top: false,
              child: subStep == 0
                  ? // Step 1: Single Centered "Continuer" Button
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          shadowColor: AppColors.primaryOrange.withValues(alpha: 0.4),
                        ),
                        onPressed: () {
                          reportProvider.nextWizardStep();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppTranslations.getText('continue', lang),
                              style: AppTextStyles.buttonText.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    )
                  : // Steps > 0: "Précédent" & "Suivant" / "Envoyer" Buttons in a Row
                  Row(
                      children: [
                        // Précédent Button
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: isDark ? AppColors.cardBgDark : Colors.white,
                              side: BorderSide(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              reportProvider.previousWizardStep();
                            },
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                              color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                            ),
                            label: Text(
                              AppTranslations.getText('previous', lang),
                              style: AppTextStyles.buttonTextOutline.copyWith(
                                color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Suivant / Envoyer Button
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              shadowColor: AppColors.primaryOrange.withValues(alpha: 0.4),
                            ),
                            onPressed: () {
                              if (isLastStep) {
                                final ref = reportProvider.submitReport();
                                setState(() {
                                  _submittedRefCode = ref;
                                });
                              } else {
                                reportProvider.nextWizardStep();
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLastStep
                                      ? AppTranslations.getText('send', lang)
                                      : AppTranslations.getText('next', lang),
                                  style: AppTextStyles.buttonText.copyWith(fontSize: 15),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  isLastStep ? Icons.send_rounded : Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
