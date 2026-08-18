import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_contacts.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/report_enum_labels.dart';
import '../../core/utils/icon_utils.dart';
import '../../core/utils/launcher_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/submission_outcome.dart';
import '../../providers/report_provider.dart';
import '../components/glass_container.dart';
import '../components/scrollable_page.dart';

/// Shown when the report could not be sent.
///
/// The screen exists because the alternative is worse than an error: a child
/// who presses "Envoyer" and sees nothing happen assumes either that the app is
/// broken or — far worse — that the report went through. So it says plainly
/// that nothing was sent, says what to do about it, and promises the answers
/// are still there, which is the first thing anyone fears losing.
class SubmissionErrorScreen extends StatelessWidget {
  const SubmissionErrorScreen({super.key, required this.failure});

  final SubmissionFailure failure;

  /// After this many failures in a row, retrying is no longer the advice.
  static const int fallbackAfterAttempts = 2;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final showFallback = provider.failedAttempts >= fallbackAfterAttempts;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.emergencyBannerBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.dangerRedStrong,
                    width: 2,
                  ),
                ),
                child: IconUtils.buildIcon(
                  FontAwesomeIcons.cloudArrowUp,
                  color: AppColors.dangerRedStrong,
                  size: 52,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.submissionErrorTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle.copyWith(
                fontSize: 22,
                color: AppColors.dangerRedStrong,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              failure.text(l10n),
              textAlign: TextAlign.center,
              style: AppTextStyles.screenSubtitle.copyWith(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Said before the buttons, not after: the fear of having to fill in
            // eleven steps again is what stops someone from pressing retry.
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconUtils.buildIcon(
                    FontAwesomeIcons.shieldHalved,
                    color: AppColors.primaryBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.submissionErrorAnswersKept,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              // Retrying is submitting again: the answers and the idempotency
              // key are both untouched, so the server sees one report.
              onPressed: () => unawaited(provider.submitReport()),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                l10n.submissionErrorRetry,
                style: AppTextStyles.buttonText.copyWith(fontSize: 15),
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: provider.dismissSubmissionError,
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
              label: Text(
                l10n.submissionErrorReview,
                style: AppTextStyles.buttonTextOutline.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),

            if (showFallback) ...[
              const SizedBox(height: 28),
              _FallbackCard(l10n: l10n),
            ],
          ],
        ),
      ),
    );
  }
}

/// Offered once retrying has stopped being a credible answer.
///
/// A report that will not send is not only a technical failure — it means
/// nobody knows. The direct line and the emergency number are both here so the
/// dead end has an exit that does not depend on the backend being up.
class _FallbackCard extends StatelessWidget {
  const _FallbackCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.primaryOrange.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.submissionErrorPersistTitle,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.submissionErrorPersistBody,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () =>
                Provider.of<ReportProvider>(context, listen: false).setTab(3),
            icon: IconUtils.buildIcon(
              FontAwesomeIcons.headset,
              color: AppColors.primaryBlue,
              size: 15,
            ),
            label: Text(
              l10n.submissionErrorContactTeam,
              style: AppTextStyles.buttonTextOutline.copyWith(
                fontSize: 13.5,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRedStrong,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () =>
                unawaited(LauncherUtils.makePhoneCall(AppContacts.police)),
            icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
            label: Text(
              l10n.submissionErrorCallPolice,
              style: AppTextStyles.buttonText.copyWith(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}
