import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../core/utils/launcher_utils.dart';
import '../../providers/theme_provider.dart';
import '../components/animated_entrance.dart';
import '../components/glass_container.dart';
import '../components/interactive_card.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final List<Map<String, dynamic>> adviceList = [
      {
        'title': 'Ne réponds pas',
        'subtitle': 'Évite de continuer la discussion avec la personne.',
        'icon': FontAwesomeIcons.hand,
        'bgColor': isDark ? AppColors.dangerRedBgDark : const Color(0xFFFDE8E8),
        'iconColor': AppColors.dangerRed,
      },
      {
        'title': 'Garde les preuves',
        'subtitle': 'Conserve les captures, liens, messages ou comptes.',
        'icon': FontAwesomeIcons.boxArchive,
        'bgColor': isDark ? AppColors.cardBgDark : AppColors.whatsappBgLight,
        'iconColor': isDark ? AppColors.accentCyan : AppColors.primaryBlue,
      },
      {
        'title': 'Parle à un adulte',
        'subtitle': 'Un parent, un enseignant ou une personne de confiance.',
        'icon': FontAwesomeIcons.userGroup,
        'bgColor': isDark ? const Color(0xFF431407) : const Color(0xFFFFEDD5),
        'iconColor': AppColors.primaryOrange,
      },
      {
        'title': 'Bloque et signale',
        'subtitle': "Utilise les options de l'application ou du réseau social.",
        'icon': FontAwesomeIcons.userSlash,
        'bgColor': isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
        'iconColor': const Color(0xFF0284C7),
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Badge
            AnimatedEntrance(
              delay: const Duration(milliseconds: 50),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardBgDark : AppColors.whatsappBgLight,
                    borderRadius: BorderRadius.circular(8),
                    border: isDark
                        ? Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Text(
                    'RESSOURCES',
                    style: TextStyle(
                      color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 100),
              child: Text(
                "Que faire maintenant ?",
                style: AppTextStyles.screenTitle.copyWith(color: AppColors.primaryOrange),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 140),
              child: Text(
                "Des gestes simples peuvent te protéger.",
                style: AppTextStyles.screenSubtitle.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Advice Cards with staggered animations & Glassmorphism
            ...List.generate(adviceList.length, (index) {
              final item = adviceList[index];
              return AnimatedEntrance(
                delay: Duration(milliseconds: 180 + (index * 80)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: InteractiveCard(
                    borderRadius: BorderRadius.circular(20),
                    child: GlassContainer(
                      isDarkMode: isDark,
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: item['bgColor'] as Color,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconUtils.buildIcon(
                              item['icon'],
                              color: item['iconColor'] as Color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: AppTextStyles.cardTitle.copyWith(
                                    fontSize: 15.5,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['subtitle'] as String,
                                  style: AppTextStyles.cardSubtitle.copyWith(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Emergency Banner
            AnimatedEntrance(
              delay: const Duration(milliseconds: 520),
              child: InteractiveCard(
                onTap: () {
                  LauncherUtils.makePhoneCall('19');
                },
                borderRadius: BorderRadius.circular(16),
                child: GlassContainer(
                  isDarkMode: isDark,
                  padding: const EdgeInsets.all(18),
                  borderColor: AppColors.primaryOrange.withValues(alpha: 0.4),
                  gradient: isDark
                      ? LinearGradient(
                          colors: [
                            AppColors.emergencyBannerBgDark,
                            AppColors.cardBgDark,
                          ],
                        )
                      : null,
                  child: Row(
                    children: [
                      IconUtils.buildIcon(
                        FontAwesomeIcons.shieldHeart,
                        color: AppColors.primaryOrange,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "En cas de danger immédiat",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Police 19 · Gendarmerie 177",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconUtils.buildIcon(
                        FontAwesomeIcons.phoneVolume,
                        color: AppColors.primaryOrange,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
