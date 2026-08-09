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

typedef _OptionStyle = ({FaIconData icon, String subtitle, String badge});

class Step3AssistanceScreen extends StatelessWidget {
  const Step3AssistanceScreen({super.key});

  static _OptionStyle _styleFor(AssistanceNeed need, AppLocalizations l10n) =>
      switch (need) {
        AssistanceNeed.wanted => (
          icon: FontAwesomeIcons.handshakeAngle,
          subtitle: l10n.assistanceWantedSubtitle,
          badge: l10n.badgeYes,
        ),
        AssistanceNeed.none => (
          icon: FontAwesomeIcons.ban,
          subtitle: l10n.assistanceNoneSubtitle,
          badge: l10n.badgeNo,
        ),
        AssistanceNeed.unsure => (
          icon: FontAwesomeIcons.circleQuestion,
          subtitle: l10n.assistanceUnsureSubtitle,
          badge: l10n.badgeUnsure,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final selectedAssistance = provider.currentReport.assistanceNeeded;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.assistanceQuestion,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.assistanceSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 24),
          ...AssistanceNeed.values.map((option) {
            final isSelected = selectedAssistance == option;
            final style = _styleFor(option, l10n);

            return Semantics(
              button: true,
              selected: isSelected,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    provider.updateReport(assistanceNeeded: option);
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
                              Row(
                                children: [
                                  Text(
                                    option.label(l10n),
                                    style: AppTextStyles.cardTitle.copyWith(
                                      fontSize: 15.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      style.badge,
                                      style: const TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
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
        ],
      ),
    );
  }
}
