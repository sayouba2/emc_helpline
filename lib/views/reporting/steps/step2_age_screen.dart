import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../chatbot/emc_chatbot_screen.dart';
import '../../components/glass_container.dart';

class Step2AgeScreen extends StatelessWidget {
  const Step2AgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final selectedAge = provider.currentReport.ageRange;

    final List<Map<String, dynamic>> options = [
      {
        'title': '5 à 12 ans',
        'icon': Icons.child_care_rounded,
        'isYouth': false,
      },
      {
        'title': '13 à 17 ans',
        'icon': Icons.sentiment_satisfied_alt_rounded,
        'isYouth': true,
      },
      {
        'title': '18 ans et plus',
        'icon': Icons.person_rounded,
        'isYouth': true,
      },
      {
        'title': 'Je préfère ne pas le dire',
        'icon': Icons.help_outline_rounded,
        'isYouth': false,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Quel âge as-tu ?",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ces informations nous aident à mieux t'accompagner.",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          ...options.map((opt) {
            final isSelected = selectedAge == opt['title'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  provider.updateReport(ageRange: opt['title']);
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? AppColors.primaryBlue.withValues(alpha: 0.35)
                            : AppColors.whatsappBgLight)
                        : (isDark ? AppColors.cardBgDark : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? AppColors.accentCyan : AppColors.primaryBlue)
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? AppColors.accentCyan.withValues(alpha: 0.2)
                                  : AppColors.primaryBlue.withValues(alpha: 0.12))
                              : (isDark ? AppColors.bgDark : AppColors.bgLight),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          opt['icon'] as IconData,
                          color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          opt['title'] as String,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 15,
                            color: isSelected
                                ? (isDark ? AppColors.accentCyan : AppColors.primaryBlue)
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected
                            ? (isDark ? AppColors.accentCyan : AppColors.primaryBlue)
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Chatbot EMC Redirection Banner (Affiché si la tranche d'âge >12 ans est sélectionnée)
          if (selectedAge == '13 à 17 ans' || selectedAge == '18 ans et plus') ...[
            const SizedBox(height: 16),
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconUtils.buildIcon(
                          FontAwesomeIcons.robot,
                          color: AppColors.primaryOrange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Besoin d'aide interactive immédiate ? (+12 ans)",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Comme tu as plus de 12 ans, tu peux poser tes questions en direct au Chatbot EMC ou continuer ton signalement.",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmcChatbotScreen()),
                      );
                    },
                    icon: IconUtils.buildIcon(FontAwesomeIcons.comments, size: 15, color: Colors.white),
                    label: const Text(
                      "Ouvrir le Chatbot EMC (+12 ans)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
