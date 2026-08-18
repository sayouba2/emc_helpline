import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/report_provider.dart';
import '../components/interactive_card.dart';
import '../components/scrollable_page.dart';
import '../tracking/track_request_screen.dart';

/// What the report tab opens on.
///
/// The tab used to drop straight into the eleven-step form. Someone who only
/// wanted to know where their case stood had to find "Suivre ma demande" on the
/// home screen. Both paths are offered here instead — the home call to action
/// still goes straight to the form for whoever has already decided.
class ReportLandingScreen extends StatelessWidget {
  const ReportLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listening, not just reading: the resume card below appears and vanishes
    // with the provider's state.
    final provider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.reportLandingTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reportLandingSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenSubtitle,
            ),
            const SizedBox(height: 32),
            // Only when a finished report failed to send. It comes first and
            // stays orange because "Faire un signalement" just below wipes the
            // answers — the recovery has to be the more obvious of the two.
            if (provider.hasUnsentReport) ...[
              _ActionCard(
                icon: FontAwesomeIcons.rotateRight,
                title: l10n.reportLandingResume,
                subtitle: l10n.reportLandingResumeSubtitle,
                accent: AppColors.primaryOrange,
                isPrimary: true,
                onTap: provider.resumeUnsentReport,
              ),
              const SizedBox(height: 16),
            ],
            _ActionCard(
              icon: FontAwesomeIcons.fileShield,
              title: l10n.reportLandingNew,
              subtitle: l10n.reportLandingNewSubtitle,
              accent: AppColors.primaryOrange,
              isPrimary: !provider.hasUnsentReport,
              onTap: provider.startNewReport,
            ),
            const SizedBox(height: 16),
            _ActionCard(
              icon: FontAwesomeIcons.magnifyingGlassChart,
              title: l10n.trackRequest,
              subtitle: l10n.reportLandingTrackSubtitle,
              accent: AppColors.primaryBlue,
              isPrimary: false,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const TrackRequestScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isPrimary,
    required this.onTap,
  });

  final FaIconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  /// The reporting path is filled, the tracking one outlined: in an emergency
  /// the eye should land on the first without reading either.
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: ExcludeSemantics(
        child: InteractiveCard(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isPrimary ? accent : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent, width: isPrimary ? 0 : 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.2)
                        : accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconUtils.buildIcon(
                    icon,
                    color: isPrimary ? Colors.white : accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isPrimary ? Colors.white : accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: isPrimary
                              ? Colors.white.withValues(alpha: 0.9)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
