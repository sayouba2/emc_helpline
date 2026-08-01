import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../providers/report_provider.dart';
import '../../providers/theme_provider.dart';
import '../components/glass_container.dart';

class ReportSuccessScreen extends StatelessWidget {
  final String referenceCode;

  const ReportSuccessScreen({
    super.key,
    required this.referenceCode,
  });

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Success Icon Circle
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardBgDark : AppColors.whatsappBgLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.accentCyan : AppColors.primaryBlue).withValues(alpha: 0.25),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: IconUtils.buildIcon(
                  FontAwesomeIcons.circleCheck,
                  color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Signalement envoyé",
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle.copyWith(
                color: AppColors.primaryOrange,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Ton signalement a été envoyé avec succès. Une personne spécialisée va l'étudier pour t'aider.",
              textAlign: TextAlign.center,
              style: AppTextStyles.screenSubtitle.copyWith(
                fontSize: 13.5,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),

            // Reference Code Box
            GlassContainer(
              isDarkMode: isDark,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              borderColor: (isDark ? AppColors.accentCyan : AppColors.primaryBlue).withValues(alpha: 0.4),
              child: Column(
                children: [
                  Text(
                    "NUMÉRO DE RÉFÉRENCE",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    referenceCode,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info Card
            GlassContainer(
              isDarkMode: isDark,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconUtils.buildIcon(
                    FontAwesomeIcons.circleInfo,
                    color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Conserve ce numéro précieusement. Il te permettra de suivre l'avancement de ton dossier lors de tes prochains échanges avec l'équipe.",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // CTA Button 1: "Voir les conseils"
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              onPressed: () {
                reportProvider.setTab(2); // Switch to Ressources tab
              },
              icon: IconUtils.buildIcon(FontAwesomeIcons.lightbulb, size: 16),
              label: const Text(
                "Voir les conseils",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 12),

            // CTA Button 2: "Contacter EMC Helpline"
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                reportProvider.setTab(3); // Switch to Contact tab
              },
              icon: IconUtils.buildIcon(
                FontAwesomeIcons.headset,
                color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                size: 16,
              ),
              label: Text(
                "Contacter EMC Helpline",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
