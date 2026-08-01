import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../providers/report_provider.dart';

class Step3AssistanceScreen extends StatelessWidget {
  const Step3AssistanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final selectedAssistance = provider.currentReport.wantsAssistance;

    final List<Map<String, dynamic>> options = [
      {
        'title': 'Accompagnement',
        'subtitle': 'Aide juridique ou psychologique.',
        'badge': 'OUI',
        'badgeBg': AppColors.cardBg,
        'badgeColor': AppColors.primaryBlue,
        'icon': FontAwesomeIcons.handshakeAngle,
      },
      {
        'title': "Pas d'accompagnement",
        'subtitle': 'Je veux seulement signaler le contenu.',
        'badge': 'NON',
        'badgeBg': AppColors.cardBg,
        'badgeColor': AppColors.primaryBlue,
        'icon': FontAwesomeIcons.ban,
      },
      {
        'title': 'Je ne sais pas',
        'subtitle': "Je veux qu'on m'aide à choisir.",
        'badge': '?',
        'badgeBg': AppColors.cardBg,
        'badgeColor': AppColors.primaryBlue,
        'icon': FontAwesomeIcons.circleQuestion,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Veux-tu de l'aide ?",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          const SizedBox(height: 8),
          Text(
            "Des personnes spécialisées peuvent t'accompagner.",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 24),
          ...options.map((opt) {
            final isSelected = selectedAssistance == opt['title'];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  provider.updateReport(wantsAssistance: opt['title']);
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
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppColors.primaryBlue.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
                            Row(
                              children: [
                                Text(
                                  opt['title'] as String,
                                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15.5),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: opt['badgeBg'] as Color,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    opt['badge'] as String,
                                    style: TextStyle(
                                      color: opt['badgeColor'] as Color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }
}
