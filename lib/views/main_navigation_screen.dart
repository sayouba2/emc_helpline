import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/icon_utils.dart';
import '../providers/report_provider.dart';
import '../providers/theme_provider.dart';
import 'components/animated_indexed_stack.dart';
import 'components/glass_container.dart';
import 'components/header_app_bar.dart';
import 'home/home_screen.dart';
import 'reporting/reporting_wizard_screen.dart';
import 'resources/resources_screen.dart';
import 'contact/contact_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // If panic mode is active, show discrete screen (Amélioration Sécurité)
    if (reportProvider.isPanicMode) {
      return _buildPanicScreen(context, reportProvider, isDark);
    }

    final List<Widget> pages = [
      const HomeScreen(),
      const ReportingWizardScreen(),
      const ResourcesScreen(),
      const ContactScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      extendBody: true,
      appBar: const HeaderAppBar(),
      body: AnimatedIndexedStack(
        index: reportProvider.currentTab,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: GlassContainer(
            isDarkMode: isDark,
            blur: 16,
            opacity: isDark ? 0.8 : 0.9,
            borderRadius: BorderRadius.circular(30),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  currentIndex: reportProvider.currentTab,
                  label: 'Accueil',
                  icon: FontAwesomeIcons.house,
                  isDark: isDark,
                  onTap: () => reportProvider.setTab(0),
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  currentIndex: reportProvider.currentTab,
                  label: 'Signaler',
                  icon: FontAwesomeIcons.bullhorn,
                  isDark: isDark,
                  onTap: () {
                    if (reportProvider.currentTab != 1) {
                      reportProvider.startNewReport();
                    }
                  },
                ),
                _buildNavItem(
                  context: context,
                  index: 2,
                  currentIndex: reportProvider.currentTab,
                  label: 'Ressources',
                  icon: FontAwesomeIcons.lightbulb,
                  isDark: isDark,
                  onTap: () => reportProvider.setTab(2),
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  currentIndex: reportProvider.currentTab,
                  label: 'Contact',
                  icon: FontAwesomeIcons.headset,
                  isDark: isDark,
                  onTap: () => reportProvider.setTab(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required int currentIndex,
    required String label,
    required dynamic icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isSelected = index == currentIndex;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.primaryOrange.withValues(alpha: 0.25)
                  : AppColors.primaryOrange.withValues(alpha: 0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryOrange.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconUtils.buildIcon(
              icon,
              size: isSelected ? 18 : 16,
              color: isSelected
                  ? AppColors.primaryOrange
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Discrete view shown when Panic Mode is triggered
  Widget _buildPanicScreen(BuildContext context, ReportProvider provider, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : Colors.white,
      appBar: AppBar(
        title: Text(
          "Météo du jour",
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? AppColors.cardBgDark : Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: IconUtils.buildIcon(FontAwesomeIcons.arrowsRotate, color: Colors.blue, size: 16),
            onPressed: () {
              provider.togglePanicMode();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconUtils.buildIcon(FontAwesomeIcons.sun, size: 72, color: Colors.amber),
              const SizedBox(height: 20),
              Text(
                "24°C - Ensoleillé",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Rabat, Maroc",
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                ),
              ),
              const SizedBox(height: 44),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.cardBgDark : Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade400,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  provider.togglePanicMode();
                },
                icon: IconUtils.buildIcon(FontAwesomeIcons.lockOpen, size: 14),
                label: const Text("Quitter le mode discrétion"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
