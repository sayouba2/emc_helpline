import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/app_translations.dart';
import '../../core/utils/icon_utils.dart';
import '../../core/utils/launcher_utils.dart';
import '../../providers/report_provider.dart';
import '../../providers/theme_provider.dart';
import '../chatbot/emc_chatbot_screen.dart';
import '../components/animated_entrance.dart';
import '../components/glass_container.dart';
import '../components/interactive_card.dart';
import '../components/pulsing_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final lang = reportProvider.currentLanguage;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 18.0, right: 18.0, top: 18.0, bottom: 90.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Confidential & Secure + Hero CTA Card
            AnimatedEntrance(
              delay: const Duration(milliseconds: 100),
              child: _buildHeroCard(context, reportProvider, isDark, lang),
            ),
            const SizedBox(height: 20),

            // Chatbot EMC (+12 ans) Banner Card
            AnimatedEntrance(
              delay: const Duration(milliseconds: 160),
              child: _buildChatbotBanner(context, isDark, lang),
            ),
            const SizedBox(height: 24),

            // Emergency Numbers Section Header
            AnimatedEntrance(
              delay: const Duration(milliseconds: 220),
              child: Row(
                children: [
                  IconUtils.buildIcon(
                    FontAwesomeIcons.phoneVolume,
                    color: AppColors.dangerRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.getText('emergency_numbers', lang),
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 17,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Police 19 Card
            AnimatedEntrance(
              delay: const Duration(milliseconds: 280),
              child: _buildEmergencyCard(
                context: context,
                title: AppTranslations.getText('police', lang),
                subtitle: AppTranslations.getText('police_sub', lang),
                number: '19',
                icon: FontAwesomeIcons.shieldHeart,
                iconColor: AppColors.dangerRed,
                bgColor: isDark ? AppColors.dangerRedBgDark : AppColors.dangerRedBgLight,
                isDark: isDark,
                onTap: () async {
                  final launched = await LauncherUtils.makePhoneCall('19');
                  if (!launched && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("L'émulateur ne supporte pas les appels téléphoniques directs (Police: 19)."),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // Gendarmerie 177 Card
            AnimatedEntrance(
              delay: const Duration(milliseconds: 360),
              child: _buildEmergencyCard(
                context: context,
                title: AppTranslations.getText('gendarmerie', lang),
                subtitle: AppTranslations.getText('gendarmerie_sub', lang),
                number: '177',
                icon: FontAwesomeIcons.userShield,
                iconColor: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                bgColor: isDark ? AppColors.cardBgDark : AppColors.whatsappBgLight,
                isDark: isDark,
                onTap: () async {
                  final launched = await LauncherUtils.makePhoneCall('177');
                  if (!launched && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("L'émulateur ne supporte pas les appels téléphoniques directs (Gendarmerie: 177)."),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // How it works card ("Comment ça marche ?")
            AnimatedEntrance(
              delay: const Duration(milliseconds: 440),
              child: _buildHowItWorksCard(isDark, lang),
            ),
            const SizedBox(height: 24),

            // User's Submitted Reports
            if (reportProvider.history.isNotEmpty) ...[
              AnimatedEntrance(
                delay: const Duration(milliseconds: 500),
                child: Row(
                  children: [
                    IconUtils.buildIcon(
                      FontAwesomeIcons.clockRotateLeft,
                      color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.getText('recent_reports', lang),
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 17,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...reportProvider.history.map((report) => AnimatedEntrance(
                delay: const Duration(milliseconds: 560),
                child: _buildReportHistoryItem(context, report, isDark),
              )),
              const SizedBox(height: 24),
            ],

            // CMRPI & EMC Helpline Prominent Institutional Footer
            AnimatedEntrance(
              delay: const Duration(milliseconds: 600),
              child: _buildPartnerFooter(isDark, lang),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, ReportProvider provider, bool isDark, String lang) {
    return GlassContainer(
      isDarkMode: isDark,
      padding: const EdgeInsets.all(22),
      gradient: isDark ? AppColors.heroGradientDark : AppColors.heroGradientLight,
      child: Column(
        children: [
          // Badge "CONFIDENTIEL & SÉCURISÉ"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardBgDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryOrange.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.15),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconUtils.buildIcon(
                  FontAwesomeIcons.shieldHalved,
                  size: 13,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(width: 8),
                Text(
                  AppTranslations.getText('confidential_badge', lang),
                  style: AppTextStyles.badgeText.copyWith(
                    fontSize: 10.5,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            AppTranslations.getText('hero_title', lang),
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.primaryBlue,
              fontSize: 26,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppTranslations.getText('hero_sub', lang),
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          PulsingWidget(
            minScale: 0.98,
            maxScale: 1.025,
            duration: const Duration(milliseconds: 1600),
            child: InteractiveCard(
              onTap: () {
                provider.startNewReport();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: AppColors.orangeCtaGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconUtils.buildIcon(FontAwesomeIcons.fileShield, size: 18, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      AppTranslations.getText('report_now', lang),
                      style: AppTextStyles.buttonText.copyWith(
                        fontSize: 15,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatbotBanner(BuildContext context, bool isDark, String lang) {
    return InteractiveCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmcChatbotScreen()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        isDarkMode: isDark,
        padding: const EdgeInsets.all(18),
        borderColor: AppColors.primaryOrange.withValues(alpha: 0.35),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconUtils.buildIcon(
                FontAwesomeIcons.robot,
                color: AppColors.primaryOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.getText('chatbot_banner_title', lang),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppTranslations.getText('chatbot_banner_sub', lang),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppTranslations.getText('open_chatbot', lang)} ->',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String number,
    required dynamic icon,
    required Color iconColor,
    required Color bgColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InteractiveCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        isDarkMode: isDark,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconUtils.buildIcon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 16,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.cardSubtitle.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard(bool isDark, String lang) {
    return GlassContainer(
      isDarkMode: isDark,
      padding: const EdgeInsets.all(18),
      borderColor: (isDark ? AppColors.accentCyan : AppColors.primaryBlue).withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconUtils.buildIcon(
              FontAwesomeIcons.circleQuestion,
              color: isDark ? AppColors.bgDark : Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.getText('how_it_works', lang),
                  style: AppTextStyles.cardTitle.copyWith(
                    color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTranslations.getText('how_it_works_sub', lang),
                  style: AppTextStyles.cardSubtitle.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportHistoryItem(BuildContext context, dynamic report, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        isDarkMode: isDark,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconUtils.buildIcon(
              FontAwesomeIcons.circleCheck,
              color: AppColors.primaryOrange,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.referenceCode ?? 'REF-EMC-2026',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${report.incidentType ?? "Signalement"} • ${report.platform ?? "Plateforme non précisée"}',
                    style: AppTextStyles.cardSubtitle.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.primaryBlue.withValues(alpha: 0.3) : AppColors.whatsappBgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'En cours',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerFooter(bool isDark, String lang) {
    return GlassContainer(
      isDarkMode: isDark,
      padding: const EdgeInsets.all(16),
      borderColor: (isDark ? AppColors.accentCyan : AppColors.primaryBlue).withValues(alpha: 0.35),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // EMC Logo Card
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 100),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardBgDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1.2,
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/emc.png',
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const SizedBox(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '×',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                  ),
                ),
              ),
              // CMRPI Logo Card
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 100),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardBgDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1.2,
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/cmrpi.png',
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const SizedBox(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppTranslations.getText('cmrpi_partner', lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
