import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../components/glass_container.dart';
import '../../components/interactive_card.dart';

class Step1WhoScreen extends StatelessWidget {
  const Step1WhoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final currentSelection = reportProvider.currentReport.whoFor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Qui a besoin d'aide ?",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Sélectionnez la personne concernée par le signalement.",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          _buildOptionCard(
            context,
            title: "Pour moi",
            subtitle: "Je souhaite signaler une situation qui me concerne directement.",
            icon: FontAwesomeIcons.user,
            isSelected: currentSelection == "Pour moi",
            isDark: isDark,
            onTap: () {
              reportProvider.updateReport(whoFor: "Pour moi");
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            title: "Pour quelqu'un d'autre",
            subtitle: "Je signale pour un ami, un collègue ou une connaissance.",
            icon: FontAwesomeIcons.userGroup,
            isSelected: currentSelection == "Pour quelqu'un d'autre",
            isDark: isDark,
            onTap: () {
              reportProvider.updateReport(whoFor: "Pour quelqu'un d'autre");
            },
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
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InteractiveCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        isDarkMode: isDark,
        padding: const EdgeInsets.all(24),
        borderColor: isSelected
            ? (isDark ? AppColors.accentCyan : AppColors.primaryBlue)
            : null,
        borderWidth: isSelected ? 2.5 : 1,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? AppColors.primaryBlue.withValues(alpha: 0.4)
                        : AppColors.whatsappBgLight)
                    : (isDark ? AppColors.cardBgDark : AppColors.bgLight),
                shape: BoxShape.circle,
              ),
              child: IconUtils.buildIcon(
                icon,
                size: 28,
                color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 17,
                color: isSelected
                    ? (isDark ? AppColors.accentCyan : AppColors.primaryBlue)
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardSubtitle.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
