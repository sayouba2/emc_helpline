import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/report_enum_labels.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/report_enums.dart';
import '../../../providers/report_provider.dart';
import '../../components/choice_card.dart';
import '../../components/step_layout.dart';

typedef _Option = ({FaIconData icon, String subtitle, String badge});

/// Step 6 — whether the user wants to be accompanied. The answer decides
/// whether steps 7 and 8 are asked at all.
class StepAssistanceScreen extends StatelessWidget {
  const StepAssistanceScreen({super.key});

  static _Option _optionFor(AssistanceNeed need, AppLocalizations l10n) =>
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
    final selected = provider.currentReport.assistanceNeeded;

    return StepLayout(
      title: l10n.assistanceQuestion,
      subtitle: l10n.assistanceSubtitle,
      children: [
        for (final option in AssistanceNeed.values)
          Builder(
            builder: (context) {
              final data = _optionFor(option, l10n);
              return ChoiceCard(
                label: option.label(l10n),
                subtitle: data.subtitle,
                badge: data.badge,
                icon: data.icon,
                isSelected: selected == option,
                onTap: () => provider.updateReport(assistanceNeeded: option),
              );
            },
          ),
      ],
    );
  }
}
