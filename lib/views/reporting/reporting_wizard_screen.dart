import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/report_provider.dart';
import '../../providers/theme_provider.dart';
import '../components/animated_indexed_stack.dart';
import '../components/glass_container.dart';
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

          // Bottom Action Bar (Précédent / Suivant / Envoyer)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 85, top: 8),
            child: GlassContainer(
              isDarkMode: isDark,
              padding: const EdgeInsets.all(12),
              borderRadius: BorderRadius.circular(20),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Précédent Button
                    if (subStep > 0)
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                            "Précédent",
                            style: AppTextStyles.buttonTextOutline.copyWith(
                              color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),

                    const SizedBox(width: 12),

                    // Suivant / Envoyer Button
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
                              isLastStep ? "Envoyer" : "Suivant",
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
          ),
        ],
      ),
    );
  }
}
