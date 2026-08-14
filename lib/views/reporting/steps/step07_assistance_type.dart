import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/report_enum_labels.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/report_enums.dart';
import '../../../providers/report_provider.dart';
import '../../components/choice_card.dart';
import '../../components/step_layout.dart';

typedef _Option = ({FaIconData icon, String subtitle});

/// Step 7 — which kind of support. Only reached by someone who asked for it.
class StepAssistanceTypeScreen extends StatelessWidget {
  const StepAssistanceTypeScreen({super.key});

  static _Option _optionFor(AssistanceType type, AppLocalizations l10n) =>
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
    final selected = provider.currentReport.assistanceType;

    return StepLayout(
      title: l10n.assistanceTypeQuestion,
      subtitle: l10n.assistanceTypeSubtitle,
      children: [
        for (final option in AssistanceType.values)
          Builder(
            builder: (context) {
              final data = _optionFor(option, l10n);
              return ChoiceCard(
                label: option.label(l10n),
                subtitle: data.subtitle,
                icon: data.icon,
                isSelected: selected == option,
                onTap: () => provider.updateReport(assistanceType: option),
              );
            },
          ),
        const SizedBox(height: 8),
        _InfoNote(text: l10n.assistanceTypeInfo),
      ],
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.emergencyBannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FaIcon(
            FontAwesomeIcons.circleInfo,
            color: AppColors.primaryOrange,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
