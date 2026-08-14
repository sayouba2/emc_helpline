import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/report_enum_labels.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/report_enums.dart';
import '../../../providers/report_provider.dart';
import '../../components/choice_card.dart';
import '../../components/step_layout.dart';

/// Step 2 — how the user wants to be referred to.
class StepGenderScreen extends StatelessWidget {
  const StepGenderScreen({super.key});

  static IconData _iconFor(Gender gender) => switch (gender) {
    Gender.female => Icons.female_rounded,
    Gender.male => Icons.male_rounded,
    Gender.undisclosed => Icons.visibility_off_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final selected = provider.currentReport.gender;

    return StepLayout(
      title: l10n.genderQuestion,
      subtitle: l10n.genderSubtitle,
      children: [
        for (final option in Gender.values)
          ChoiceCard(
            label: option.label(l10n),
            icon: _iconFor(option),
            isSelected: selected == option,
            onTap: () => provider.updateReport(gender: option),
          ),
      ],
    );
  }
}
