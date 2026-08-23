import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_contacts.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/icon_utils.dart';
import '../core/utils/launcher_utils.dart';
import '../l10n/app_localizations.dart';
import 'components/scrollable_page.dart';

/// Shown once, at first launch, before anything else.
///
/// Not a tour of the features. Someone opening this application has usually had
/// something happen to them, and owes it no patience. It says the three things
/// that shape everything afterwards — no name is asked, the reference number is
/// how you come back, and notifications will be offered later — then gets out
/// of the way.
///
/// **It requests no permission.** Android stops showing the notification dialog
/// after two refusals, and a cold ask, before anyone knows what the app does,
/// earns refusals. Saying in advance what will be asked, and what it would look
/// like on a shared phone, is what this screen is for; the asking happens where
/// the reference number is, when there is finally something to be told about.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ScrollablePage(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Whoever is in danger right now should not be reading an
                    // introduction. This comes before everything else.
                    _EmergencyRow(l10n: l10n),
                    const SizedBox(height: 32),

                    Text(
                      l10n.onboardingTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitle.copyWith(fontSize: 23),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.onboardingSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenSubtitle.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    _Point(
                      icon: FontAwesomeIcons.userSecret,
                      title: l10n.onboardingAnonymousTitle,
                      body: l10n.onboardingAnonymousBody,
                    ),
                    _Point(
                      icon: FontAwesomeIcons.hashtag,
                      title: l10n.onboardingReferenceTitle,
                      body: l10n.onboardingReferenceBody,
                    ),
                    _Point(
                      icon: FontAwesomeIcons.bell,
                      title: l10n.onboardingNotifyTitle,
                      // Says what will be asked, and what a message would look
                      // like to someone else holding the phone. Asks nothing.
                      body: l10n.onboardingNotifyBody,
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                ),
                onPressed: onDone,
                child: Text(
                  l10n.onboardingStart,
                  style: AppTextStyles.buttonText.copyWith(fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyRow extends StatelessWidget {
  const _EmergencyRow({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: l10n.a11yCall(l10n.police, AppContacts.police),
      child: ExcludeSemantics(
        child: Material(
          color: AppColors.emergencyBannerBg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () =>
                unawaited(LauncherUtils.makePhoneCall(AppContacts.police)),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.dangerRedStrong),
              ),
              child: Row(
                children: [
                  IconUtils.buildIcon(
                    FontAwesomeIcons.phoneVolume,
                    color: AppColors.dangerRedStrong,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.onboardingEmergency,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dangerRedStrong,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final dynamic icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconUtils.buildIcon(
              icon,
              color: AppColors.primaryBlue,
              size: 17,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
