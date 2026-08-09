import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../models/report_enums.dart';
import '../../../core/localization/report_enum_labels.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/report_provider.dart';
import '../../components/glass_container.dart';
import '../../components/interactive_card.dart';

typedef _BrandStyle = ({FaIconData icon, Color color, Color background});

class Step3PlatformScreen extends StatelessWidget {
  const Step3PlatformScreen({super.key});

  static _BrandStyle _styleFor(ReportPlatform platform) => switch (platform) {
    ReportPlatform.whatsapp => (
      icon: FontAwesomeIcons.whatsapp,
      color: AppColors.whatsappGreen,
      background: AppColors.whatsappBg,
    ),
    ReportPlatform.instagram => (
      icon: FontAwesomeIcons.instagram,
      color: AppColors.instagramPink,
      background: AppColors.instagramBg,
    ),
    ReportPlatform.tiktok => (
      icon: FontAwesomeIcons.tiktok,
      color: AppColors.tiktokDark,
      background: AppColors.tiktokBg,
    ),
    ReportPlatform.facebook => (
      icon: FontAwesomeIcons.facebook,
      color: AppColors.facebookBlue,
      background: AppColors.facebookBg,
    ),
    ReportPlatform.onlineGame => (
      icon: FontAwesomeIcons.gamepad,
      color: AppColors.gamingPurple,
      background: AppColors.gamingBg,
    ),
    ReportPlatform.messenger => (
      icon: FontAwesomeIcons.facebookMessenger,
      color: AppColors.messengerBlue,
      background: AppColors.messengerBg,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final selectedPlatform = reportProvider.currentReport.platform;
    const platforms = ReportPlatform.values;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.platformQuestion,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle.copyWith(
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.platformSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle.copyWith(
              color: AppColors.textSecondary,
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
              final isSelected = selectedPlatform == item;
              final style = _styleFor(item);
              final brandColor = style.color;
              final brandBg = style.background;

              return Semantics(
                button: true,
                selected: isSelected,
                child: InteractiveCard(
                  onTap: () {
                    reportProvider.updateReport(platform: item);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderColor: isSelected ? brandColor : null,
                    borderWidth: isSelected ? 2.5 : 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : brandBg,
                            shape: BoxShape.circle,
                          ),
                          child: IconUtils.buildIcon(
                            style.icon,
                            color: brandColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.label(l10n),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 14,
                            color: isSelected
                                ? brandColor
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
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
