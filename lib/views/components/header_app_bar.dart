import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/report_provider.dart';

class HeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HeaderAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(84);

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    // The effective locale, which may come from the device rather than from an
    // explicit choice in the picker below.
    final languageCode = Localizations.localeOf(context).languageCode;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 1.0,
      leadingWidth: 95,
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
              height: 56,
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
          Text(
            l10n.appTitle,
            style: AppTextStyles.headerTitle.copyWith(
              color: AppColors.primaryBlue,
              letterSpacing: -0.3,
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          // Sélecteur de langue sous forme de pill élégant au centre
          Semantics(
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
            height: 56,
            width: 85,
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
