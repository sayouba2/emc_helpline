import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../providers/report_provider.dart';
import '../../providers/theme_provider.dart';

class HeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HeaderAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return AppBar(
      backgroundColor: isDark ? AppColors.bgDark : Colors.white,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0.5,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 14.0, top: 10, bottom: 10),
        child: InkWell(
          onTap: () => reportProvider.setTab(0),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardBgDark : AppColors.whatsappBgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.primaryBlue.withValues(alpha: 0.15),
              ),
            ),
            child: Center(
              child: IconUtils.buildIcon(
                FontAwesomeIcons.shieldHalved,
                color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                size: 18,
              ),
            ),
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'EMC Helpline',
            style: AppTextStyles.headerTitle.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.primaryBlue,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Children, Youth, and Women',
            style: AppTextStyles.headerSubtitle.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
      actions: [
        // Dark / Light Mode Toggle Button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: IconButton(
            tooltip: isDark ? 'Passer au mode clair' : 'Passer au mode sombre',
            style: IconButton.styleFrom(
              backgroundColor: isDark ? AppColors.cardBgDark : AppColors.bgLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: IconUtils.buildIcon(
              isDark ? FontAwesomeIcons.sun : FontAwesomeIcons.moon,
              color: isDark ? const Color(0xFFFBBF24) : AppColors.primaryBlue,
              size: 16,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ),
        // Language Switcher Button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: IconButton(
            tooltip: 'Changer la langue',
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
        // Quick Exit Discretion Button
        Padding(
          padding: const EdgeInsets.only(right: 14, left: 4, top: 10, bottom: 10),
          child: IconButton(
            tooltip: 'Mode Discrétion / Quitter rapidement',
            style: IconButton.styleFrom(
              backgroundColor: isDark ? AppColors.dangerRedBgDark : AppColors.dangerRedBgLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: IconUtils.buildIcon(
              FontAwesomeIcons.eyeSlash,
              color: AppColors.dangerRed,
              size: 15,
            ),
            onPressed: () {
              reportProvider.togglePanicMode();
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
                'Choisir la langue / Language',
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
