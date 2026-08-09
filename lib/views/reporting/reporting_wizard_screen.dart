import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/report_enum_labels.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/report_provider.dart';
import '../components/animated_screen_switcher.dart';
import '../components/stepper_widget.dart';
import 'report_success_screen.dart';
import 'sending_screen.dart';
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

class ReportingWizardScreen extends StatelessWidget {
  const ReportingWizardScreen({super.key});

  int _getStepperNumber(int subStep) {
    if (subStep == ReportProvider.stepWho) return 1;
    if (subStep <= ReportProvider.stepGender) return 2;
    if (subStep <= ReportProvider.stepUrgency) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);

    if (reportProvider.isSubmitting) return const SendingScreen();

    final submittedRefCode = reportProvider.submittedRefCode;
    if (submittedRefCode != null) {
      return ReportSuccessScreen(referenceCode: submittedRefCode);
    }

    final subStep = reportProvider.wizardStep;
    final stepperNumber = _getStepperNumber(subStep);
    final isLastStep = subStep == ReportProvider.stepSummary;
    final blockingMessage = reportProvider.currentStepError?.text(l10n);
    final canAdvance = blockingMessage == null;

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
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Stepper bar
          StepperWidget(currentStep: stepperNumber),
          const Divider(height: 1, color: AppColors.border),

          // Current Step Content with AnimatedIndexedStack
          Expanded(
            child: AnimatedScreenSwitcher(
              index: subStep.clamp(0, stepWidgets.length - 1),
              children: stepWidgets,
            ),
          ),

          // Bottom Action Bar (Direct buttons without enclosing card)
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 74,
              top: 4,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (blockingMessage != null) ...[
                    _buildStepHint(blockingMessage),
                    const SizedBox(height: 10),
                  ],
                  if (subStep == ReportProvider.stepWho)
                    // Step 1: Single Centered "Continuer" Button
                    SizedBox(
                      width: double.infinity,
                      child: _buildForwardButton(
                        label: l10n.actionContinue,
                        icon: Icons.arrow_forward_rounded,
                        verticalPadding: 15,
                        isEnabled: canAdvance,
                        onPressed: reportProvider.nextWizardStep,
                      ),
                    )
                  else
                    // Steps > 0: "Précédent" & "Suivant" / "Envoyer" Buttons in a Row
                    Row(
                      children: [
                        // Précédent Button
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: AppColors.border,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: reportProvider.previousWizardStep,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                              color: AppColors.primaryBlue,
                            ),
                            label: Text(
                              l10n.actionPrevious,
                              style: AppTextStyles.buttonTextOutline.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Suivant / Envoyer Button
                        Expanded(
                          child: _buildForwardButton(
                            label: isLastStep
                                ? l10n.actionSend
                                : l10n.actionNext,
                            icon: isLastStep
                                ? Icons.send_rounded
                                : Icons.arrow_forward_rounded,
                            verticalPadding: 14,
                            isEnabled: canAdvance,
                            // Le Chatbot (+12 ans) reste accessible depuis la
                            // bannière de l'étape "âge" : "Suivant" ne doit
                            // jamais détourner le parcours vers celui-ci.
                            onPressed: isLastStep
                                ? () => unawaited(reportProvider.submitReport())
                                : reportProvider.nextWizardStep,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tells the user what the current step still expects, right above the
  /// disabled "Suivant" button so the block never looks like a broken app.
  Widget _buildStepHint(String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 15,
          color: AppColors.primaryOrange,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForwardButton({
    required String label,
    required IconData icon,
    required double verticalPadding,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    final contentColor = isEnabled ? Colors.white : Colors.white70;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primaryOrange.withValues(
          alpha: 0.35,
        ),
        disabledForegroundColor: Colors.white70,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isEnabled ? 3 : 0,
        shadowColor: AppColors.primaryOrange.withValues(alpha: 0.4),
      ),
      onPressed: isEnabled ? onPressed : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.buttonText.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: contentColor,
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 18, color: contentColor),
        ],
      ),
    );
  }
}
