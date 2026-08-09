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
import '../../components/scrollable_page.dart';

class Step3IncidentTypeScreen extends StatelessWidget {
  const Step3IncidentTypeScreen({super.key});

  static FaIconData _iconFor(IncidentType type) => switch (type) {
    IncidentType.hateSpeech => FontAwesomeIcons.commentSlash,
    IncidentType.discrimination => FontAwesomeIcons.scaleUnbalanced,
    IncidentType.defamation => FontAwesomeIcons.fileLines,
    IncidentType.identityTheft => FontAwesomeIcons.idCard,
    IncidentType.intimateImages => FontAwesomeIcons.eyeSlash,
    IncidentType.threat => FontAwesomeIcons.triangleExclamation,
    IncidentType.other => FontAwesomeIcons.ellipsis,
  };

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final selectedType = provider.currentReport.incidentType;

    return ScrollablePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.incidentQuestion,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.incidentSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 20),
          ...IncidentType.values.map((option) {
            final isSelected = selectedType == option;

            return Semantics(
              button: true,
              selected: isSelected,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    provider.updateReport(incidentType: option);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.cardBg : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.border,
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
                                : AppColors.bg,
                            shape: BoxShape.circle,
                          ),
                          child: IconUtils.buildIcon(
                            _iconFor(option),
                            color: AppColors.primaryBlue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            option.label(l10n),
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 14.5,
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          IconUtils.buildIcon(
                            FontAwesomeIcons.circleCheck,
                            color: AppColors.primaryBlue,
                            size: 18,
                          ),
                      ],
                    ),
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
