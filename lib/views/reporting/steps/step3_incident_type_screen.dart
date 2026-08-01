import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../providers/report_provider.dart';

class Step3IncidentTypeScreen extends StatelessWidget {
  const Step3IncidentTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final selectedType = provider.currentReport.incidentType;

    final List<Map<String, dynamic>> options = [
      {
        'title': 'Propos de haine',
        'icon': FontAwesomeIcons.commentSlash,
      },
      {
        'title': 'Propos raciste ou discriminatoire',
        'icon': FontAwesomeIcons.scaleUnbalanced,
      },
      {
        'title': 'Diffamation',
        'icon': FontAwesomeIcons.fileLines,
      },
      {
        'title': "Usurpation d'identité",
        'icon': FontAwesomeIcons.idCard,
      },
      {
        'title': 'Photos intimes ou personnelles',
        'icon': FontAwesomeIcons.eyeSlash,
      },
      {
        'title': 'Menace',
        'icon': FontAwesomeIcons.triangleExclamation,
      },
      {
        'title': 'Autres',
        'icon': FontAwesomeIcons.ellipsis,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Que s'est-il passé ?",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          const SizedBox(height: 8),
          Text(
            "Reste calme. Choisis ce qui ressemble le plus à ta situation.",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 20),
          ...options.map((opt) {
            final isSelected = selectedType == opt['title'];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  provider.updateReport(incidentType: opt['title']);
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.cardBg : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppColors.primaryBlue.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.01),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryBlue.withValues(alpha: 0.12)
                              : AppColors.bgLight,
                          shape: BoxShape.circle,
                        ),
                        child: IconUtils.buildIcon(
                          opt['icon'],
                          color: AppColors.primaryBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          opt['title'] as String,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 14.5,
                            color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        IconUtils.buildIcon(FontAwesomeIcons.circleCheck, color: AppColors.primaryBlue, size: 18),
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
