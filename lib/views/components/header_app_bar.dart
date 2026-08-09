import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/report_provider.dart';

/// The header: EMC logo, app title, language picker, CMRPI logo.
///
/// Its height is computed from the context rather than hardcoded, and
/// [toolbarHeight] is set to match — without it the `AppBar` lays its content
/// out in the default 56dp while the `Scaffold` reserves the preferred height,
/// which crammed everything against the top of the screen and pushed the title
/// under the punch-hole camera on devices that have one.
///
/// The `Scaffold` adds the status bar / display cutout inset on top of this
/// height, so the content always starts below the notch.
class HeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HeaderAppBar({super.key, required this.height});

  /// Height of the bar itself, excluding the system inset the Scaffold adds.
  final double height;

  static const double _baseHeight = 84;

  /// Grows with the user's font size, but not without bound: past ~1.3 the
  /// header would eat the screen, so the title ellipsises instead.
  static double heightFor(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return (_baseHeight * textScale.clamp(1.0, 1.3)).roundToDouble();
  }

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    // The effective locale, which may come from the device rather than from an
    // explicit choice in the picker below.
    final languageCode = Localizations.localeOf(context).languageCode;

    // Fixed widths ate more than half of a narrow screen. Both logos now take a
    // share of it, floored so they stay legible and capped so they never crowd
    // out the title.
    final width = MediaQuery.sizeOf(context).width;
    final leadingWidth = (width * 0.24).clamp(72.0, 104.0);
    final partnerWidth = (width * 0.21).clamp(60.0, 92.0);
    final logoHeight = (height - 24).clamp(32.0, 56.0);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 1.0,
      toolbarHeight: height,
      leadingWidth: leadingWidth,
      leading: Padding(
        padding: const EdgeInsets.only(left: 14.0, top: 4, bottom: 4),
        child: Semantics(
          button: true,
          label: l10n.a11yAppLogo,
          child: InkWell(
            onTap: () => reportProvider.setTab(0),
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/emc.png',
              fit: BoxFit.contain,
              height: logoHeight,
              errorBuilder: (context, error, stackTrace) => IconUtils.buildIcon(
                FontAwesomeIcons.shieldHalved,
                color: AppColors.primaryBlue,
                size: 28,
              ),
            ),
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              l10n.appTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headerTitle.copyWith(
                color: AppColors.primaryBlue,
                letterSpacing: -0.3,
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Sélecteur de langue sous forme de pill élégant au centre
          Flexible(
            child: Semantics(
              button: true,
              label: l10n.changeLanguage,
              child: InkWell(
                onTap: () => _showLanguageDialog(context, reportProvider, l10n),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          switch (languageCode) {
                            'ar' => '🇲🇦 ${l10n.languageArabic}',
                            'en' => '🇬🇧 ${l10n.languageEnglish}',
                            _ => '🇫🇷 ${l10n.languageFrench}',
                          },
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        // CMRPI Partner Logo (Occupe TOUT l'espace de droite sans aucune obstruction)
        Padding(
          padding: const EdgeInsets.only(
            right: 14.0,
            left: 4.0,
            top: 4,
            bottom: 4,
          ),
          child: Image.asset(
            'assets/images/cmrpi.png',
            semanticLabel: l10n.a11yPartnerLogo,
            fit: BoxFit.contain,
            height: logoHeight,
            width: partnerWidth,
            errorBuilder: (context, error, stackTrace) => IconUtils.buildIcon(
              FontAwesomeIcons.buildingColumns,
              color: AppColors.primaryBlue,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    ReportProvider provider,
    AppLocalizations l10n,
  ) {
    final languageCode = Localizations.localeOf(context).languageCode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.chooseLanguage,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildLangTile(
                context,
                provider: provider,
                code: 'fr',
                flag: '🇫🇷',
                label: l10n.languageFrench,
                selectedCode: languageCode,
              ),
              _buildLangTile(
                context,
                provider: provider,
                code: 'ar',
                flag: '🇲🇦',
                label: l10n.languageArabic,
                selectedCode: languageCode,
              ),
              _buildLangTile(
                context,
                provider: provider,
                code: 'en',
                flag: '🇬🇧',
                label: l10n.languageEnglish,
                selectedCode: languageCode,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangTile(
    BuildContext context, {
    required ReportProvider provider,
    required String code,
    required String flag,
    required String label,
    required String selectedCode,
  }) {
    final isSelected = selectedCode == code;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.whatsappBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Text(flag, style: const TextStyle(fontSize: 24)),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
          ),
        ),
        trailing: isSelected
            ? IconUtils.buildIcon(
                FontAwesomeIcons.circleCheck,
                color: AppColors.primaryBlue,
                size: 18,
              )
            : null,
        onTap: () {
          provider.setLocale(Locale(code));
          Navigator.pop(context);
        },
      ),
    );
  }
}
