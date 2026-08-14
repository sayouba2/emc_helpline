import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/report_enum_labels.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/report_enums.dart';
import '../../../providers/report_provider.dart';
import '../../components/choice_card.dart';
import '../../components/step_layout.dart';

/// Step 3 — what happened. The longest list, so the marker is a check that
/// only shows on the chosen one rather than seven empty radio dots.
class StepIncidentScreen extends StatelessWidget {
  const StepIncidentScreen({super.key});

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
    final selected = provider.currentReport.incidentType;

    return StepLayout(
      title: l10n.incidentQuestion,
      subtitle: l10n.incidentSubtitle,
      children: [
        for (final option in IncidentType.values)
          ChoiceCard(
            label: option.label(l10n),
            icon: _iconFor(option),
            isSelected: selected == option,
            marker: ChoiceMarker.check,
            onTap: () => provider.updateReport(incidentType: option),
          ),
      ],
    );
  }
}
