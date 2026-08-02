import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/app_translations.dart';
import '../../core/utils/icon_utils.dart';
import '../../providers/report_provider.dart';
import '../../providers/theme_provider.dart';

class HeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HeaderAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(84);

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final lang = reportProvider.currentLanguage;

    return AppBar(
      backgroundColor: isDark ? AppColors.bgDark : Colors.white,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 1.0,
      leadingWidth: 95,
      leading: Padding(
        padding: const EdgeInsets.only(left: 14.0, top: 6, bottom: 6),
        child: InkWell(
          onTap: () => reportProvider.setTab(0),
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/emc.png',
            fit: BoxFit.contain,
            height: 56,
            errorBuilder: (context, error, stackTrace) => IconUtils.buildIcon(
              FontAwesomeIcons.shieldHalved,
              color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
              size: 28,
            ),
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppTranslations.getText('app_title', lang),
            style: AppTextStyles.headerTitle.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.primaryBlue,
              letterSpacing: -0.3,
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          // Sélecteur de langue sous forme de pill élégant au centre
          InkWell(
            onTap: () => _showLanguageDialog(context, reportProvider, isDark),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardBgDark : AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? AppColors.accentCyan : AppColors.primaryBlue).withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lang == 'ar' ? '🇲🇦 العربية' : (lang == 'en' ? '🇬🇧 English' : '🇫🇷 Français'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 14,
                    color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        // CMRPI Partner Logo (Occupe TOUT l'espace de droite sans aucune obstruction)
        Padding(
          padding: const EdgeInsets.only(right: 14.0, left: 4.0, top: 6, bottom: 6),
          child: Image.asset(
            'assets/images/cmrpi.png',
            fit: BoxFit.contain,
            height: 56,
            width: 85,
            errorBuilder: (context, error, stackTrace) => IconUtils.buildIcon(
              FontAwesomeIcons.buildingColumns,
              color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context, ReportProvider provider, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardBgDark : Colors.white,
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
                'Choisir la langue / اختر اللغة',
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 18,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 16),
              _buildLangTile(
                context,
                provider: provider,
                code: 'fr',
                flag: '🇫🇷',
                label: 'Français',
                isDark: isDark,
              ),
              _buildLangTile(
                context,
                provider: provider,
                code: 'ar',
                flag: '🇲🇦',
                label: 'العربية (Arabe)',
                isDark: isDark,
              ),
              _buildLangTile(
                context,
                provider: provider,
                code: 'en',
                flag: '🇬🇧',
                label: 'English',
                isDark: isDark,
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
    required bool isDark,
  }) {
    final isSelected = provider.currentLanguage == code;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppColors.primaryBlue.withValues(alpha: 0.3) : AppColors.whatsappBgLight)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Text(flag, style: const TextStyle(fontSize: 24)),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (isDark ? AppColors.accentCyan : AppColors.primaryBlue)
                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
        ),
        trailing: isSelected
            ? IconUtils.buildIcon(
                FontAwesomeIcons.circleCheck,
                color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                size: 18,
              )
            : null,
        onTap: () {
          provider.setLanguage(code);
          Navigator.pop(context);
        },
      ),
    );
  }
}
