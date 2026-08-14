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

/// Step 0 — who the report is for.
///
/// Two tiles side by side rather than two full-width cards: at full width they
/// read as sections of a page instead of a choice to make. The anonymity
/// promise stays on this screen, where a child decides whether to report at all.
class StepWhoScreen extends StatelessWidget {
  const StepWhoScreen({super.key});

  static FaIconData _iconFor(WhoFor who) => switch (who) {
    WhoFor.self => FontAwesomeIcons.user,
    WhoFor.someoneElse => FontAwesomeIcons.userGroup,
  };

  static String _subtitleFor(WhoFor who, AppLocalizations l10n) =>
      switch (who) {
        WhoFor.self => l10n.whoForSelfSubtitle,
        WhoFor.someoneElse => l10n.whoForSomeoneElseSubtitle,
      };

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final selected = provider.currentReport.whoFor;

    return StepLayout(
      title: l10n.whoNeedsHelp,
      subtitle: l10n.whoNeedsHelpSubtitle,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in WhoFor.values) ...[
                if (option != WhoFor.values.first) const SizedBox(width: 12),
                Expanded(
                  child: ChoiceTile(
                    label: option.label(l10n),
                    subtitle: _subtitleFor(option, l10n),
                    icon: _iconFor(option),
                    isSelected: selected == option,
                    onTap: () => provider.updateReport(whoFor: option),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.userSecret,
              color: AppColors.primaryBlue,
              size: 14,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.anonymitySubtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
