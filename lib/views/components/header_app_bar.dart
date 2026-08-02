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
  Size get preferredSize => const Size.fromHeight(80);

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
      leadingWidth: 105,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
        child: InkWell(
          onTap: () => reportProvider.setTab(0),
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/emc.png',
            fit: BoxFit.contain,
            height: 54,
            width: 76,
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
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppTranslations.getText('app_subtitle', lang),
            style: AppTextStyles.headerSubtitle.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        // CMRPI Partner Logo (Direct sans cadre/box, grand et très visible)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Image.asset(
            'assets/images/cmrpi.png',
            fit: BoxFit.contain,
            height: 52,
            width: 68,
            errorBuilder: (context, error, stackTrace) => IconUtils.buildIcon(
              FontAwesomeIcons.buildingColumns,
              color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
              size: 26,
            ),
          ),
        ),

        // Language Switcher Button (FR / AR / EN)
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4, top: 10, bottom: 10),
          child: IconButton(
            tooltip: AppTranslations.getText('change_language', lang),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? AppColors.cardBgDark : AppColors.bgLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: IconUtils.buildIcon(
              FontAwesomeIcons.globe,
              color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
              size: 16,
            ),
            onPressed: () {
              _showLanguageDialog(context, reportProvider, isDark);
            },
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
