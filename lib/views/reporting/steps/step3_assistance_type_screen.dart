import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../providers/report_provider.dart';

class Step3AssistanceTypeScreen extends StatelessWidget {
  const Step3AssistanceTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final selectedType = provider.currentReport.assistanceType;

    final List<Map<String, dynamic>> options = [
      {
        'title': 'Aide juridique',
        'subtitle': 'Pour comprendre tes droits, signaler ou déposer plainte.',
        'icon': FontAwesomeIcons.scaleBalanced,
      },
      {
        'title': 'Aide psychologique',
        'subtitle': 'Pour parler, être écouté(e) et rassuré(e).',
        'icon': FontAwesomeIcons.heartPulse,
      },
      {
        'title': 'Les deux',
        'subtitle': "J'ai besoin d'une aide juridique et psychologique.",
        'icon': FontAwesomeIcons.handsHoldingChild,
      },
      {
        'title': 'Je ne sais pas',
        'subtitle': "Je veux qu'une personne m'aide à choisir.",
        'icon': FontAwesomeIcons.circleQuestion,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'AIDE DEMANDÉE',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "De quel type d'aide as-tu besoin ?",
            style: AppTextStyles.screenTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            "Choisis l'aide qui correspond le mieux à ta situation.",
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 20),
          ...options.map((opt) {
            final isSelected = selectedType == opt['title'];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  provider.updateReport(assistanceType: opt['title']);
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(18),
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
                          color: isSelected
                              ? AppColors.primaryBlue.withValues(alpha: 0.12)
                              : AppColors.bgLight,
                          shape: BoxShape.circle,
                        ),
                        child: IconUtils.buildIcon(
                          opt['icon'],
                          color: AppColors.primaryBlue,
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
                              style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 3),
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
          const SizedBox(height: 12),

          // Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.emergencyBannerBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                IconUtils.buildIcon(FontAwesomeIcons.circleInfo, color: AppColors.primaryOrange, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Tu peux choisir 'Je ne sais pas'. L'important est de demander de l'aide.",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textPrimary.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
