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

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final List<Map<String, dynamic>> contactMethods = [
      {
        'title': 'WhatsApp',
        'subtitle': 'Ouvrir la discussion EMC Helpline.',
        'actionText': 'Discuter ->',
        'icon': FontAwesomeIcons.whatsapp,
        'iconBg': isDark ? AppColors.whatsappBgDark : AppColors.whatsappBgLight,
        'iconColor': AppColors.whatsappGreen,
        'onTap': () => LauncherUtils.openWhatsApp('212624405889'),
      },
      {
        'title': 'Appeler',
        'subtitle': '+212 624 405 889',
        'actionText': 'Appeler ->',
        'icon': FontAwesomeIcons.phoneVolume,
        'iconBg': isDark ? AppColors.cardBgDark : AppColors.whatsappBgLight,
        'iconColor': isDark ? AppColors.accentCyan : AppColors.primaryBlue,
        'onTap': () => LauncherUtils.makePhoneCall('+212624405889'),
      },
      {
        'title': 'E-mail',
        'subtitle': 'emchelpline@cyberconfiance.ma',
        'actionText': 'Écrire ->',
        'icon': FontAwesomeIcons.envelope,
        'iconBg': isDark ? AppColors.gamingBgDark : const Color(0xFFF3E8FF),
        'iconColor': const Color(0xFFA855F7),
        'onTap': () => LauncherUtils.sendEmail('emchelpline@cyberconfiance.ma', subject: 'Demande de contact - EMC Helpline'),
      },
      {
        'title': 'Formulaire web',
        'subtitle': 'evigilance.ma/fr/signaler',
        'actionText': 'Visiter',
        'isExternal': true,
        'icon': FontAwesomeIcons.globe,
        'iconBg': isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
        'iconColor': const Color(0xFFF59E0B),
        'onTap': () => LauncherUtils.openWebPage('https://evigilance.ma/fr/signaler'),
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
                    "BESOIN D'AIDE ?",
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
                "Contacte EMC Helpline",
                style: AppTextStyles.screenTitle.copyWith(color: AppColors.primaryOrange),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 140),
              child: Text(
                "Notre équipe est disponible pour vous écouter, vous conseiller et vous accompagner en toute confidentialité.",
                style: AppTextStyles.screenSubtitle.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Contact Cards with staggered animations
            ...List.generate(contactMethods.length, (index) {
              final method = contactMethods[index];
              return AnimatedEntrance(
                delay: Duration(milliseconds: 180 + (index * 80)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: InteractiveCard(
                    borderRadius: BorderRadius.circular(20),
                    onTap: method['onTap'] as VoidCallback,
                    child: GlassContainer(
                      isDarkMode: isDark,
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: method['iconBg'] as Color,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconUtils.buildIcon(
                              method['icon'],
                              color: method['iconColor'] as Color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method['title'] as String,
                                  style: AppTextStyles.cardTitle.copyWith(
                                    fontSize: 15.5,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  method['subtitle'] as String,
                                  style: AppTextStyles.cardSubtitle.copyWith(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      method['actionText'] as String,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                                      ),
                                    ),
                                    if (method['isExternal'] == true) ...[
                                      const SizedBox(width: 6),
                                      IconUtils.buildIcon(
                                        FontAwesomeIcons.upRightFromSquare,
                                        size: 11,
                                        color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                                      ),
                                    ],
                                  ],
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

            // Warning Banner
            AnimatedEntrance(
              delay: const Duration(milliseconds: 520),
              child: GlassContainer(
                isDarkMode: isDark,
                padding: const EdgeInsets.all(16),
                borderColor: AppColors.primaryOrange.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    IconUtils.buildIcon(
                      FontAwesomeIcons.triangleExclamation,
                      color: AppColors.primaryOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "Attention : L'EMC Helpline ne remplace pas les autorités en cas de danger immédiat.",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
