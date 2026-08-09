import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_contacts.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../core/utils/launcher_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_model.dart';
import '../../core/localization/report_enum_labels.dart';
import '../../providers/report_provider.dart';
import '../components/animated_entrance.dart';
import '../components/demo_notice.dart';
import '../components/glass_container.dart';
import '../components/interactive_card.dart';
import '../components/pulsing_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 18.0,
          right: 18.0,
          top: 18.0,
          bottom: 90.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stated before anything else: the app must not read as a working
            // reporting channel while nothing is actually transmitted.
            const DemoNotice(),
            if (!kBackendEnabled) const SizedBox(height: 16),

            // Banner Confidential & Secure + Hero CTA Card
            AnimatedEntrance(
              delay: const Duration(milliseconds: 100),
              child: _buildHeroCard(context, reportProvider, l10n),
            ),
            const SizedBox(height: 24),

            // Emergency Numbers Section Header
            AnimatedEntrance(
              delay: const Duration(milliseconds: 180),
              child: Row(
                children: [
                  IconUtils.buildIcon(
                    FontAwesomeIcons.phoneVolume,
                    color: AppColors.dangerRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.emergencyNumbers,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Police 19 Card
            AnimatedEntrance(
              delay: const Duration(milliseconds: 240),
              child: _buildEmergencyCard(
                context: context,
                semanticLabel: l10n.a11yCall(l10n.police, AppContacts.police),
                title: l10n.police,
                subtitle: l10n.policeSubtitle,
                number: AppContacts.police,
                icon: FontAwesomeIcons.shieldHeart,
                iconColor: AppColors.dangerRed,
                bgColor: AppColors.dangerRedBg,
                onTap: () async {
                  final launched = await LauncherUtils.makePhoneCall(
                    AppContacts.police,
                  );
                  if (!launched && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.callFailed(AppContacts.police)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // Gendarmerie 177 Card
            AnimatedEntrance(
              delay: const Duration(milliseconds: 300),
              child: _buildEmergencyCard(
                context: context,
                semanticLabel: l10n.a11yCall(
                  l10n.gendarmerie,
                  AppContacts.gendarmerie,
                ),
                title: l10n.gendarmerie,
                subtitle: l10n.gendarmerieSubtitle,
                number: AppContacts.gendarmerie,
                icon: FontAwesomeIcons.userShield,
                iconColor: AppColors.primaryBlue,
                bgColor: AppColors.whatsappBg,
                onTap: () async {
                  final launched = await LauncherUtils.makePhoneCall(
                    AppContacts.gendarmerie,
                  );
                  if (!launched && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.callFailed(AppContacts.gendarmerie)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // How it works card ("Comment ça marche ?")
            AnimatedEntrance(
              delay: const Duration(milliseconds: 360),
              child: _buildHowItWorksCard(l10n),
            ),
            const SizedBox(height: 24),

            // User's Submitted Reports
            if (reportProvider.history.isNotEmpty) ...[
              AnimatedEntrance(
                delay: const Duration(milliseconds: 420),
                child: Row(
                  children: [
                    IconUtils.buildIcon(
                      FontAwesomeIcons.clockRotateLeft,
                      color: AppColors.primaryBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.recentReports,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...reportProvider.history.map(
                (report) => AnimatedEntrance(
                  delay: const Duration(milliseconds: 480),
                  child: _buildReportHistoryItem(context, report, l10n),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // CMRPI & EMC Helpline Prominent Institutional Footer
            AnimatedEntrance(
              delay: const Duration(milliseconds: 520),
              child: _buildPartnerFooter(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    ReportProvider provider,
    AppLocalizations l10n,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(22),
      gradient: AppColors.heroGradient,
      child: Column(
        children: [
          // Badge "CONFIDENTIEL & SÉCURISÉ"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryOrange.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.15),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconUtils.buildIcon(
                  FontAwesomeIcons.shieldHalved,
                  size: 13,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.confidentialBadge,
                    style: AppTextStyles.badgeText.copyWith(
                      fontSize: 12,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.heroTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle.copyWith(
              color: AppColors.primaryBlue,
              fontSize: 26,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.heroSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          PulsingWidget(
            maxScale: 1.025,
            duration: const Duration(milliseconds: 1600),
            child: InteractiveCard(
              onTap: () {
                provider.startNewReport();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.orangeCtaGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconUtils.buildIcon(
                      FontAwesomeIcons.fileShield,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        l10n.reportNow,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.buttonText.copyWith(
                          fontSize: 15,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard({
    required BuildContext context,
    required String semanticLabel,
    required String title,
    required String subtitle,
    required String number,
    required dynamic icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    // One node for the whole card: a screen reader announces "Appeler la
    // Police, numéro 19" instead of spelling out each fragment of the layout.
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: InteractiveCard(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconUtils.buildIcon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.cardSubtitle.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    number,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard(AppLocalizations l10n) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.primaryBlue.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconUtils.buildIcon(
              FontAwesomeIcons.circleQuestion,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.howItWorks,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: AppColors.primaryBlue,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.howItWorksSubtitle,
                  style: AppTextStyles.cardSubtitle.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportHistoryItem(
    BuildContext context,
    ReportModel report,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconUtils.buildIcon(
              FontAwesomeIcons.circleCheck,
              color: AppColors.primaryOrange,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.referenceCode ?? 'REF-EMC-2026',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.reportHistorySubtitle(
                      report.incidentType?.label(l10n) ??
                          l10n.reportFallbackIncident,
                      report.platform?.label(l10n) ??
                          l10n.reportFallbackPlatform,
                    ),
                    style: AppTextStyles.cardSubtitle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.whatsappBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.reportStatusInProgress,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerFooter(AppLocalizations l10n) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.primaryBlue.withValues(alpha: 0.35),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // EMC Logo
              Flexible(
                child: Image.asset(
                  'assets/images/emc.png',
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const SizedBox(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '×',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              // CMRPI Logo
              Flexible(
                child: Image.asset(
                  'assets/images/cmrpi.png',
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const SizedBox(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.cmrpiPartner,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
