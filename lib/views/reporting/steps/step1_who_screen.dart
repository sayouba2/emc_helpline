import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/report_enums.dart';
import '../../../providers/report_provider.dart';
import '../../components/glass_container.dart';
import '../../components/interactive_card.dart';
import '../../components/scrollable_page.dart';

/// First step: who the report is for.
///
/// The pseudonym used to be chosen here. It moved to the contact step, where it
/// is actually used — a nickname only matters once someone has asked to be
/// called back. Only the anonymity promise stays, since this is where a child
/// decides whether to report at all.
class Step1WhoScreen extends StatelessWidget {
  const Step1WhoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final currentSelection = reportProvider.currentReport.whoFor;

    return ScrollablePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.whoNeedsHelp,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle.copyWith(
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.whoNeedsHelpSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Les deux options côte à côte : pleine largeur, elles se lisaient
          // comme des sections plutôt que comme un choix à faire.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildOptionCard(
                    context,
                    title: l10n.whoForSelf,
                    subtitle: l10n.whoForSelfSubtitle,
                    icon: FontAwesomeIcons.user,
                    isSelected: currentSelection == WhoFor.self,
                    onTap: () {
                      reportProvider.updateReport(whoFor: WhoFor.self);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOptionCard(
                    context,
                    title: l10n.whoForSomeoneElse,
                    subtitle: l10n.whoForSomeoneElseSubtitle,
                    icon: FontAwesomeIcons.userGroup,
                    isSelected: currentSelection == WhoFor.someoneElse,
                    onTap: () {
                      reportProvider.updateReport(whoFor: WhoFor.someoneElse);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              IconUtils.buildIcon(
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
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required dynamic icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InteractiveCard(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          borderColor: isSelected ? AppColors.primaryBlue : null,
          borderWidth: isSelected ? 2.5 : 1,
          child: Column(
            children: [
              // A radio marker makes it read as a choice, which two big cards
              // side by side otherwise do not.
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: isSelected ? AppColors.primaryBlue : AppColors.border,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.whatsappBg : AppColors.bg,
                  shape: BoxShape.circle,
                ),
                child: IconUtils.buildIcon(
                  icon,
                  size: 20,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 14.5,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.cardSubtitle.copyWith(
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
