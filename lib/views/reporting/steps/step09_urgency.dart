import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_contacts.dart';
import '../../../core/localization/report_enum_labels.dart';
import '../../../core/utils/launcher_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/report_enums.dart';
import '../../../providers/report_provider.dart';
import '../../components/choice_card.dart';
import '../../components/interactive_card.dart';
import '../../components/step_layout.dart';

typedef _Option = ({FaIconData icon, String subtitle, Color accent});

/// Step 9 — how urgent it is, with the emergency numbers one tap away.
class StepUrgencyScreen extends StatelessWidget {
  const StepUrgencyScreen({super.key});

  static _Option _optionFor(UrgencyLevel level, AppLocalizations l10n) =>
      switch (level) {
        UrgencyLevel.urgent => (
          icon: FontAwesomeIcons.triangleExclamation,
          subtitle: l10n.urgencyUrgentSubtitle,
          // The one answer that changes how the report is handled reads as red.
          accent: AppColors.dangerRedStrong,
        ),
        UrgencyLevel.notUrgent => (
          icon: FontAwesomeIcons.circleCheck,
          subtitle: l10n.urgencyNotUrgentSubtitle,
          accent: AppColors.primaryBlue,
        ),
        UrgencyLevel.unsure => (
          icon: FontAwesomeIcons.circleQuestion,
          subtitle: l10n.urgencyUnsureSubtitle,
          accent: AppColors.primaryBlue,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final selected = provider.currentReport.urgencyLevel;

    return StepLayout(
      title: l10n.urgencyQuestion,
      subtitle: l10n.urgencySubtitle,
      children: [
        for (final option in UrgencyLevel.values)
          Builder(
            builder: (context) {
              final data = _optionFor(option, l10n);
              return ChoiceCard(
                label: option.label(l10n),
                subtitle: data.subtitle,
                icon: data.icon,
                accentColor: data.accent,
                isSelected: selected == option,
                onTap: () => provider.updateReport(urgencyLevel: option),
              );
            },
          ),
        const SizedBox(height: 8),
        _EmergencyBanner(l10n: l10n),
      ],
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: l10n.a11yCall(l10n.police, AppContacts.police),
      child: ExcludeSemantics(
        child: InteractiveCard(
          onTap: () => LauncherUtils.makePhoneCall(AppContacts.police),
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
                const FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.immediateDangerPrefix.trim(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.emergencyNumbersInline,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                const FaIcon(
                  FontAwesomeIcons.phoneVolume,
                  color: AppColors.primaryOrange,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
