import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_contacts.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../core/utils/launcher_utils.dart';
import '../../l10n/app_localizations.dart';
import '../components/animated_entrance.dart';
import '../components/glass_container.dart';
import '../components/interactive_card.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final List<Map<String, dynamic>> adviceList = [
      {
        'title': l10n.tipDoNotReplyTitle,
        'subtitle': l10n.tipDoNotReplyBody,
        'icon': FontAwesomeIcons.hand,
        'bgColor': const Color(0xFFFDE8E8),
        'iconColor': AppColors.dangerRed,
      },
      {
        'title': l10n.tipKeepEvidenceTitle,
        'subtitle': l10n.tipKeepEvidenceBody,
        'icon': FontAwesomeIcons.boxArchive,
        'bgColor': AppColors.whatsappBg,
        'iconColor': AppColors.primaryBlue,
      },
      {
        'title': l10n.tipTalkToAdultTitle,
        'subtitle': l10n.tipTalkToAdultBody,
        'icon': FontAwesomeIcons.userGroup,
        'bgColor': const Color(0xFFFFEDD5),
        'iconColor': AppColors.primaryOrange,
      },
      {
        'title': l10n.tipBlockReportTitle,
        'subtitle': l10n.tipBlockReportBody,
        'icon': FontAwesomeIcons.userSlash,
        'bgColor': const Color(0xFFE0F2FE),
        'iconColor': const Color(0xFF0284C7),
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 90,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Badge
            AnimatedEntrance(
              delay: const Duration(milliseconds: 50),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.whatsappBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.resourcesBadge,
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
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
                l10n.resourcesTitle,
                style: AppTextStyles.screenTitle.copyWith(
                  color: AppColors.primaryOrange,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 140),
              child: Text(
                l10n.resourcesSubtitle,
                style: AppTextStyles.screenSubtitle.copyWith(
                  color: AppColors.textSecondary,
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
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['subtitle'] as String,
                                  style: AppTextStyles.cardSubtitle.copyWith(
                                    color: AppColors.textSecondary,
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
                  LauncherUtils.makePhoneCall(AppContacts.police);
                },
                borderRadius: BorderRadius.circular(16),
                child: GlassContainer(
                  padding: const EdgeInsets.all(18),
                  borderColor: AppColors.primaryOrange.withValues(alpha: 0.4),
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
                              l10n.immediateDangerTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.emergencyNumbersInline,
                              style: const TextStyle(
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
