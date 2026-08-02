import 'dart:math';
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

  final List<String> _suggestedPseudos = [
    'HérosDiscret42',
    'ÉtoileSecrète99',
    'PhoenixCalme12',
    'AigleProtecteur',
    'CyberAmiConfidentiel',
    'GardiendesMers77',
    'SuperAnonyme2026',
  ];

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

  void _generateRandomPseudo() {
    final random = Random();
    final chosen = _suggestedPseudos[random.nextInt(_suggestedPseudos.length)];
    setState(() {
      _pseudoController.text = chosen;
    });
    Provider.of<ReportProvider>(context, listen: false).updateReport(pseudo: chosen);
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

          // Anonymity & Pseudonym Card (Garantie Anonymat dès le premier contact)
          GlassContainer(
            isDarkMode: isDark,
            padding: const EdgeInsets.all(18),
            borderColor: AppColors.primaryOrange.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: IconUtils.buildIcon(
                        FontAwesomeIcons.userSecret,
                        color: AppColors.primaryOrange,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Anonymat Garanti & Pseudo",
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            "Aucun nom réel ni donnée personnelle n'est requis.",
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _pseudoController,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryOrange,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    reportProvider.updateReport(pseudo: val);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppTranslations.getText('pseudo_info', lang),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _generateRandomPseudo,
                      icon: const Text('🎲', style: TextStyle(fontSize: 12)),
                      label: const Text(
                        'Pseudo auto',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                  ],
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
