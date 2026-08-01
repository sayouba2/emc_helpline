import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../core/utils/launcher_utils.dart';
import '../../../providers/report_provider.dart';

class Step3UrgencyScreen extends StatelessWidget {
  const Step3UrgencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final selectedUrgency = provider.currentReport.urgency;

    final List<Map<String, dynamic>> options = [
      {
        'title': "Oui, c'est urgent",
        'subtitle': "Je suis en danger ou très inquiet.",
        'badge': '!',
        'badgeColor': AppColors.dangerRed,
        'badgeBg': AppColors.dangerRedBg,
        'icon': FontAwesomeIcons.triangleExclamation,
      },
      {
        'title': "Non",
        'subtitle': "Je veux signaler, mais ce n'est pas immédiat.",
        'badge': 'OK',
        'badgeColor': AppColors.primaryBlue,
        'badgeBg': AppColors.cardBg,
        'icon': FontAwesomeIcons.circleCheck,
      },
      {
        'title': "Je ne sais pas",
        'subtitle': "Je veux être aidé pour comprendre.",
        'badge': '?',
        'badgeColor': AppColors.primaryBlue,
        'badgeBg': AppColors.cardBg,
        'icon': FontAwesomeIcons.circleQuestion,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Est-ce urgent ?",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          const SizedBox(height: 8),
          Text(
            "Dis-nous si tu es en danger maintenant.",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 24),
          ...options.map((opt) {
            final isSelected = selectedUrgency == opt['title'];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  provider.updateReport(urgency: opt['title']);
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.cardBg : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: opt['badgeBg'] as Color,
                          shape: BoxShape.circle,
                        ),
                        child: IconUtils.buildIcon(
                          opt['icon'],
                          color: opt['badgeColor'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt['title'] as String,
                              style: AppTextStyles.cardTitle.copyWith(fontSize: 15.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              opt['subtitle'] as String,
                              style: AppTextStyles.cardSubtitle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),

          // Danger Banner
          InkWell(
            onTap: () {
              LauncherUtils.makePhoneCall('19');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.emergencyBannerBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  IconUtils.buildIcon(FontAwesomeIcons.triangleExclamation, color: AppColors.primaryOrange, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        children: [
                          TextSpan(text: "Danger immédiat : ", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: "Police 19 · Gendarmerie 177", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryOrange)),
                        ],
                      ),
                    ),
                  ),
                  IconUtils.buildIcon(FontAwesomeIcons.phoneVolume, color: AppColors.primaryOrange, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
