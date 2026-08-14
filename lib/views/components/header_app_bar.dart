import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/report_provider.dart';
import '../settings/settings_screen.dart';
import 'language_picker.dart';

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
    // Encoche latérale en paysage : le fond blanc de l'AppBar continue de
    // couvrir toute la largeur, seuls les logos s'en écartent.
    final sideInset = MediaQuery.paddingOf(context);
    final leadingWidth = (width * 0.24).clamp(72.0, 104.0) + sideInset.left;
    final partnerWidth = (width * 0.17).clamp(52.0, 76.0);
    final logoHeight = (height - 24).clamp(32.0, 56.0);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 1.0,
      toolbarHeight: height,
      leadingWidth: leadingWidth,
      leading: Padding(
        padding: EdgeInsetsDirectional.only(
          start: 14.0 + sideInset.left,
          top: 4,
          bottom: 4,
        ),
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
                onTap: () => showLanguagePicker(context),
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
        // Le tooltip d'IconButton pose un `tooltip` sémantique, pas un `label` :
        // sans ce Semantics, un lecteur d'écran n'a rien pour nommer le bouton.
        Semantics(
          button: true,
          label: l10n.settingsTitle,
          child: IconButton(
            // Pas de visualDensity.compact ici : elle ramenait la cible sous
            // les 48dp exigés.
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: EdgeInsets.zero,
            tooltip: l10n.settingsTitle,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            icon: IconUtils.buildIcon(
              FontAwesomeIcons.gear,
              color: AppColors.primaryBlue,
              size: 18,
            ),
          ),
        ),
        // CMRPI Partner Logo (Occupe TOUT l'espace de droite sans aucune obstruction)
        Padding(
          padding: EdgeInsetsDirectional.only(
            end: 14.0 + sideInset.right,
            start: 4.0,
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
}
