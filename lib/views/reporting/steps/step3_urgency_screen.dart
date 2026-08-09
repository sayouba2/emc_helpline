import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_contacts.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../core/utils/launcher_utils.dart';
import '../../../models/report_enums.dart';
import '../../../core/localization/report_enum_labels.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/report_provider.dart';

typedef _OptionStyle = ({
  FaIconData icon,
  String subtitle,
  Color color,
  Color background,
});

class Step3UrgencyScreen extends StatelessWidget {
  const Step3UrgencyScreen({super.key});

  static _OptionStyle _styleFor(UrgencyLevel level, AppLocalizations l10n) =>
      switch (level) {
        UrgencyLevel.urgent => (
          icon: FontAwesomeIcons.triangleExclamation,
          subtitle: l10n.urgencyUrgentSubtitle,
          color: AppColors.dangerRed,
          background: AppColors.dangerRedBg,
        ),
        UrgencyLevel.notUrgent => (
          icon: FontAwesomeIcons.circleCheck,
          subtitle: l10n.urgencyNotUrgentSubtitle,
          color: AppColors.primaryBlue,
          background: AppColors.cardBg,
        ),
        UrgencyLevel.unsure => (
          icon: FontAwesomeIcons.circleQuestion,
          subtitle: l10n.urgencyUnsureSubtitle,
          color: AppColors.primaryBlue,
          background: AppColors.cardBg,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final selectedUrgency = provider.currentReport.urgencyLevel;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.urgencyQuestion,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.urgencySubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 24),
          ...UrgencyLevel.values.map((option) {
            final isSelected = selectedUrgency == option;
            final style = _styleFor(option, l10n);

            return Semantics(
              button: true,
              selected: isSelected,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    provider.updateReport(urgencyLevel: option);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
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
                            color: style.background,
                            shape: BoxShape.circle,
                          ),
                          child: IconUtils.buildIcon(
                            style.icon,
                            color: style.color,
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
                                  fontSize: 15.5,
                                ),
                              ),
                              const SizedBox(height: 4),
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
          const SizedBox(height: 20),

          // Danger Banner
          InkWell(
            onTap: () {
              LauncherUtils.makePhoneCall(AppContacts.police);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.emergencyBannerBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  IconUtils.buildIcon(
                    FontAwesomeIcons.triangleExclamation,
                    color: AppColors.primaryOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: l10n.immediateDangerPrefix,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: l10n.emergencyNumbersInline,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconUtils.buildIcon(
                    FontAwesomeIcons.phoneVolume,
                    color: AppColors.primaryOrange,
                    size: 16,
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
