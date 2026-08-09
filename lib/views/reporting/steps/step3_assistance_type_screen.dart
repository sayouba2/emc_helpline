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

typedef _OptionStyle = ({FaIconData icon, String subtitle});

class Step3AssistanceTypeScreen extends StatelessWidget {
  const Step3AssistanceTypeScreen({super.key});

  static _OptionStyle _styleFor(AssistanceType type, AppLocalizations l10n) =>
      switch (type) {
        AssistanceType.legal => (
          icon: FontAwesomeIcons.scaleBalanced,
          subtitle: l10n.assistanceTypeLegalSubtitle,
        ),
        AssistanceType.psychological => (
          icon: FontAwesomeIcons.heartPulse,
          subtitle: l10n.assistanceTypePsychologicalSubtitle,
        ),
        AssistanceType.both => (
          icon: FontAwesomeIcons.handsHoldingChild,
          subtitle: l10n.assistanceTypeBothSubtitle,
        ),
        AssistanceType.unsure => (
          icon: FontAwesomeIcons.circleQuestion,
          subtitle: l10n.assistanceTypeUnsureSubtitle,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final selectedType = provider.currentReport.assistanceType;

    return ScrollablePage(
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
              child: Text(
                l10n.assistanceRequestedBadge,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.assistanceTypeQuestion,
            style: AppTextStyles.screenTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.assistanceTypeSubtitle,
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 20),
          ...AssistanceType.values.map((option) {
            final isSelected = selectedType == option;
            final style = _styleFor(option, l10n);

            return Semantics(
              button: true,
              selected: isSelected,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    provider.updateReport(assistanceType: option);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.cardBg : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.border,
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
                                : AppColors.bg,
                            shape: BoxShape.circle,
                          ),
                          child: IconUtils.buildIcon(
                            style.icon,
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
                                option.label(l10n),
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                style.subtitle,
                                style: AppTextStyles.cardSubtitle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
              border: Border.all(
                color: AppColors.primaryOrange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                IconUtils.buildIcon(
                  FontAwesomeIcons.circleInfo,
                  color: AppColors.primaryOrange,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.assistanceTypeInfo,
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
