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

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final List<Map<String, dynamic>> contactMethods = [
      {
        'title': 'WhatsApp',
        'subtitle': l10n.contactWhatsappSubtitle,
        'actionText': l10n.contactWhatsappAction,
        'icon': FontAwesomeIcons.whatsapp,
        'iconBg': AppColors.whatsappBg,
        'iconColor': AppColors.whatsappGreen,
        'onTap': () => LauncherUtils.openWhatsApp(AppContacts.helplineWhatsApp),
      },
      {
        'title': l10n.contactCallTitle,
        'subtitle': '+212 624 405 889',
        'actionText': l10n.contactCallAction,
        'icon': FontAwesomeIcons.phoneVolume,
        'iconBg': AppColors.whatsappBg,
        'iconColor': AppColors.primaryBlue,
        'onTap': () => LauncherUtils.makePhoneCall(AppContacts.helplinePhone),
      },
      {
        'title': l10n.fieldEmail,
        'subtitle': AppContacts.helplineEmail,
        'actionText': l10n.contactEmailAction,
        'icon': FontAwesomeIcons.envelope,
        'iconBg': const Color(0xFFF3E8FF),
        'iconColor': const Color(0xFFA855F7),
        'onTap': () => LauncherUtils.sendEmail(
          AppContacts.helplineEmail,
          subject: l10n.contactEmailSubject,
        ),
      },
      {
        'title': l10n.contactWebTitle,
        'subtitle': AppContacts.reportingPortalDisplay,
        'actionText': l10n.contactWebAction,
        'isExternal': true,
        'icon': FontAwesomeIcons.globe,
        'iconBg': const Color(0xFFFEF3C7),
        'iconColor': const Color(0xFFF59E0B),
        'onTap': () => LauncherUtils.openWebPage(AppContacts.reportingPortal),
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
                    l10n.contactBadge,
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
                l10n.contactScreenTitle,
                style: AppTextStyles.screenTitle.copyWith(
                  color: AppColors.primaryOrange,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 140),
              child: Text(
                l10n.contactScreenSubtitle,
                style: AppTextStyles.screenSubtitle.copyWith(
                  color: AppColors.textSecondary,
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
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  method['subtitle'] as String,
                                  style: AppTextStyles.cardSubtitle.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      method['actionText'] as String,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    if (method['isExternal'] == true) ...[
                                      const SizedBox(width: 6),
                                      IconUtils.buildIcon(
                                        FontAwesomeIcons.upRightFromSquare,
                                        size: 11,
                                        color: AppColors.primaryBlue,
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
                        l10n.contactWarning,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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
