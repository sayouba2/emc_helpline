import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../models/report_enums.dart';
import '../../../core/localization/report_enum_labels.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/report_provider.dart';
import '../../chatbot/emc_chatbot_screen.dart';
import '../../components/glass_container.dart';

class Step2AgeScreen extends StatelessWidget {
  const Step2AgeScreen({super.key});

  static IconData _iconFor(AgeGroup group) => switch (group) {
    AgeGroup.child => Icons.child_care_rounded,
    AgeGroup.teen => Icons.sentiment_satisfied_alt_rounded,
    AgeGroup.adult => Icons.person_rounded,
    AgeGroup.undisclosed => Icons.help_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final selectedAge = provider.currentReport.ageGroup;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.ageQuestion,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle.copyWith(
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.ageSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ...AgeGroup.values.map((option) {
            final isSelected = selectedAge == option;
            return Semantics(
              button: true,
              selected: isSelected,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    provider.updateReport(ageGroup: option);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.whatsappBg : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (AppColors.primaryBlue.withValues(
                                    alpha: 0.12,
                                  ))
                                : AppColors.bg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _iconFor(option),
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option.label(l10n),
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 15,
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppColors.primaryBlue
                              : AppColors.border,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Chatbot EMC Redirection Banner (Affiché si la tranche d'âge >12 ans est sélectionnée)
          if (selectedAge?.isChatbotEligible ?? false) ...[
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(18),
              borderColor: AppColors.primaryOrange.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(
                            alpha: 0.15,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconUtils.buildIcon(
                          FontAwesomeIcons.robot,
                          color: AppColors.primaryOrange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.chatbotBannerTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.chatbotBannerBody,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmcChatbotScreen(),
                        ),
                      );
                    },
                    icon: IconUtils.buildIcon(
                      FontAwesomeIcons.comments,
                      size: 15,
                      color: Colors.white,
                    ),
                    label: Text(
                      l10n.chatbotOpenButton,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
