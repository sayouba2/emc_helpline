import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../components/glass_container.dart';
import '../../components/interactive_card.dart';

class Step1WhoScreen extends StatefulWidget {
  const Step1WhoScreen({super.key});

  @override
  State<Step1WhoScreen> createState() => _Step1WhoScreenState();
}

class _Step1WhoScreenState extends State<Step1WhoScreen> {
  late TextEditingController _pseudoController;

  @override
  void initState() {
    super.initState();
    final report = Provider.of<ReportProvider>(context, listen: false).currentReport;
    _pseudoController = TextEditingController(text: report.pseudo ?? '');
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final lang = reportProvider.currentLanguage;
    final currentSelection = reportProvider.currentReport.whoFor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppTranslations.getText('who_needs_help', lang),
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.getText('who_needs_help_sub', lang),
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),

          // Option 1: Pour moi
          _buildOptionCard(
            context,
            title: AppTranslations.getText('for_me', lang),
            subtitle: AppTranslations.getText('for_me_sub', lang),
            icon: FontAwesomeIcons.user,
            isSelected: currentSelection == "Pour moi",
            isDark: isDark,
            onTap: () {
              reportProvider.updateReport(whoFor: "Pour moi");
            },
          ),
          const SizedBox(height: 14),

          // Option 2: Pour quelqu'un d'autre
          _buildOptionCard(
            context,
            title: AppTranslations.getText('for_someone_else', lang),
            subtitle: AppTranslations.getText('for_someone_else_sub', lang),
            icon: FontAwesomeIcons.userGroup,
            isSelected: currentSelection == "Pour quelqu'un d'autre",
            isDark: isDark,
            onTap: () {
              reportProvider.updateReport(whoFor: "Pour quelqu'un d'autre");
            },
          ),
          const SizedBox(height: 24),

          // Pseudonym Option (Option de Surnom pour l'anonymat garanti dès le 1er contact)
          GlassContainer(
            isDarkMode: isDark,
            padding: const EdgeInsets.all(18),
            borderColor: (isDark ? AppColors.accentCyan : AppColors.primaryBlue).withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconUtils.buildIcon(
                      FontAwesomeIcons.userSecret,
                      color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppTranslations.getText('pseudo_label', lang),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pseudoController,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: AppTranslations.getText('pseudo_hint', lang),
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    reportProvider.updateReport(pseudo: val);
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  AppTranslations.getText('pseudo_info', lang),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
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
        padding: const EdgeInsets.all(20),
        borderColor: isSelected
            ? (isDark ? AppColors.accentCyan : AppColors.primaryBlue)
            : null,
        borderWidth: isSelected ? 2.5 : 1,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
                size: 24,
                color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 16,
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
