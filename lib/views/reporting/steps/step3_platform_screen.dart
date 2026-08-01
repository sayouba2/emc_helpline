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

class Step3PlatformScreen extends StatelessWidget {
  const Step3PlatformScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final selectedPlatform = reportProvider.currentReport.platform;

    final List<Map<String, dynamic>> platforms = [
      {
        'title': 'WhatsApp',
        'icon': FontAwesomeIcons.whatsapp,
        'color': AppColors.whatsappGreen,
        'bg': isDark ? AppColors.whatsappBgDark : AppColors.whatsappBgLight,
      },
      {
        'title': 'Instagram',
        'icon': FontAwesomeIcons.instagram,
        'color': AppColors.instagramPink,
        'bg': isDark ? AppColors.instagramBgDark : AppColors.instagramBgLight,
      },
      {
        'title': 'TikTok',
        'icon': FontAwesomeIcons.tiktok,
        'color': isDark ? Colors.white : AppColors.tiktokDark,
        'bg': isDark ? AppColors.tiktokBgDark : AppColors.tiktokBgLight,
      },
      {
        'title': 'Facebook',
        'icon': FontAwesomeIcons.facebook,
        'color': AppColors.facebookBlue,
        'bg': isDark ? AppColors.facebookBgDark : AppColors.facebookBgLight,
      },
      {
        'title': 'Jeu en ligne',
        'icon': FontAwesomeIcons.gamepad,
        'color': AppColors.gamingPurple,
        'bg': isDark ? AppColors.gamingBgDark : AppColors.gamingBgLight,
      },
      {
        'title': 'Messenger',
        'icon': FontAwesomeIcons.facebookMessenger,
        'color': AppColors.messengerBlue,
        'bg': isDark ? AppColors.messengerBgDark : AppColors.messengerBgLight,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Où est-ce arrivé ?",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Choisis la plateforme concernée.",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: platforms.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) {
              final item = platforms[index];
              final isSelected = selectedPlatform == item['title'];
              final brandColor = item['color'] as Color;
              final brandBg = item['bg'] as Color;

              return InteractiveCard(
                onTap: () {
                  reportProvider.updateReport(platform: item['title']);
                },
                borderRadius: BorderRadius.circular(20),
                child: GlassContainer(
                  isDarkMode: isDark,
                  padding: const EdgeInsets.all(16),
                  borderColor: isSelected ? brandColor : null,
                  borderWidth: isSelected ? 2.5 : 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? (isDark ? AppColors.cardBgDark : Colors.white) : brandBg,
                          shape: BoxShape.circle,
                        ),
                        child: IconUtils.buildIcon(
                          item['icon'],
                          color: brandColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['title'] as String,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 14,
                          color: isSelected
                              ? brandColor
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
