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

typedef _BrandStyle = ({FaIconData icon, Color color, Color background});

/// Step 4 — where it happened. Each platform keeps its own brand colour, which
/// is what makes the grid scannable at a glance.
class StepPlatformScreen extends StatelessWidget {
  const StepPlatformScreen({super.key});

  static _BrandStyle _styleFor(ReportPlatform platform) => switch (platform) {
    ReportPlatform.whatsapp => (
      icon: FontAwesomeIcons.whatsapp,
      color: AppColors.whatsappGreen,
      background: AppColors.whatsappBg,
    ),
    ReportPlatform.instagram => (
      icon: FontAwesomeIcons.instagram,
      color: AppColors.instagramPink,
      background: AppColors.instagramBg,
    ),
    ReportPlatform.tiktok => (
      icon: FontAwesomeIcons.tiktok,
      color: AppColors.tiktokDark,
      background: AppColors.tiktokBg,
    ),
    ReportPlatform.facebook => (
      icon: FontAwesomeIcons.facebook,
      color: AppColors.facebookBlue,
      background: AppColors.facebookBg,
    ),
    ReportPlatform.onlineGame => (
      icon: FontAwesomeIcons.gamepad,
      color: AppColors.gamingPurple,
      background: AppColors.gamingBg,
    ),
    ReportPlatform.messenger => (
      icon: FontAwesomeIcons.facebookMessenger,
      color: AppColors.messengerBlue,
      background: AppColors.messengerBg,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final selected = provider.currentReport.platform;

    return StepLayout(
      title: l10n.platformQuestion,
      subtitle: l10n.platformSubtitle,
      children: [
        // Un Wrap plutôt qu'un GridView : la grille imposait une hauteur de
        // tuile fixe, que le contenu dépassait dès que la police grandissait.
        // Ici la hauteur suit le contenu, et le nombre de colonnes la largeur.
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final columns = (constraints.maxWidth / 180).floor().clamp(2, 4);
            final tileWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final option in ReportPlatform.values)
                  SizedBox(
                    width: tileWidth,
                    child: Builder(
                      builder: (context) {
                        final style = _styleFor(option);
                        return ChoiceTile(
                          label: option.label(l10n),
                          icon: style.icon,
                          accentColor: style.color,
                          iconBackground: selected == option
                              ? Colors.white
                              : style.background,
                          isSelected: selected == option,
                          onTap: () => provider.updateReport(platform: option),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
