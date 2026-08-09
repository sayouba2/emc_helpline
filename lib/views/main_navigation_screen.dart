import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/icon_utils.dart';
import '../l10n/app_localizations.dart';
import '../providers/report_provider.dart';
import 'components/animated_screen_switcher.dart';
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
    final l10n = AppLocalizations.of(context);

    final List<Widget> pages = [
      const HomeScreen(),
      const ReportingWizardScreen(),
      const ResourcesScreen(),
      const ContactScreen(),
    ];

    // Text direction comes from the app locale (see `main.dart`), so pushed
    // routes such as the chatbot follow it too.
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      appBar: const HeaderAppBar(),
      body: AnimatedScreenSwitcher(
        index: reportProvider.currentTab,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: GlassContainer(
            frosted: true,
            blur: 16,
            borderRadius: BorderRadius.circular(30),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  child: _buildNavItem(
                    context: context,
                    index: 0,
                    currentIndex: reportProvider.currentTab,
                    label: l10n.navHome,
                    icon: FontAwesomeIcons.house,
                    onTap: () => reportProvider.setTab(0),
                  ),
                ),
                Flexible(
                  child: _buildNavItem(
                    context: context,
                    index: 1,
                    currentIndex: reportProvider.currentTab,
                    label: l10n.navReport,
                    icon: FontAwesomeIcons.fileShield,
                    onTap: () {
                      // Repartir de zéro en arrivant sur l'onglet, mais aussi
                      // quand on y est déjà et qu'un signalement vient d'être
                      // envoyé : sinon l'écran de succès reste affiché et plus
                      // aucun nouveau signalement n'est possible.
                      if (reportProvider.currentTab != 1 ||
                          reportProvider.submittedRefCode != null) {
                        reportProvider.startNewReport();
                      }
                    },
                  ),
                ),
                Flexible(
                  child: _buildNavItem(
                    context: context,
                    index: 2,
                    currentIndex: reportProvider.currentTab,
                    label: l10n.navResources,
                    icon: FontAwesomeIcons.lightbulb,
                    onTap: () => reportProvider.setTab(2),
                  ),
                ),
                Flexible(
                  child: _buildNavItem(
                    context: context,
                    index: 3,
                    currentIndex: reportProvider.currentTab,
                    label: l10n.navContact,
                    icon: FontAwesomeIcons.headset,
                    onTap: () => reportProvider.setTab(3),
                  ),
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
    required VoidCallback onTap,
  }) {
    final isSelected = index == currentIndex;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          // 48dp minimum touch target. Deliberately no `alignment`: a Container
          // that has one expands to fill its constraints instead of hugging its
          // child, and the bottomNavigationBar slot is loosely constrained — the
          // bar grew to the full screen height. The min constraints alone are
          // passed down to the Row, which centres its children anyway.
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 16 : 12,
            vertical: 10,
          ),
          // The selected tab is a solid orange fill with white text. A
          // translucent tint looked lighter but only reached 2.78:1 against the
          // label, well under the 4.5:1 WCAG AA needs at this size.
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryOrange.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconUtils.buildIcon(
                  icon,
                  size: isSelected ? 18 : 16,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
