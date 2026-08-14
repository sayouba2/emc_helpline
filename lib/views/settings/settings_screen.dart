import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../l10n/app_localizations.dart';
import '../components/language_picker.dart';
import '../components/scrollable_page.dart';
import 'legal_document_screen.dart';

/// Language, legal documents, data notice and version.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = switch (Localizations.localeOf(context).languageCode) {
      'ar' => l10n.languageArabic,
      'en' => l10n.languageEnglish,
      _ => l10n.languageFrench,
    };

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          l10n.settingsTitle,
          style: AppTextStyles.cardTitle.copyWith(
            fontSize: 16,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ScrollablePage(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel(text: l10n.settingsLanguage),
              _SettingsTile(
                icon: FontAwesomeIcons.globe,
                title: l10n.settingsLanguage,
                trailing: language,
                onTap: () => showLanguagePicker(context),
              ),
              const SizedBox(height: 24),

              _SectionLabel(text: l10n.settingsData),
              _SettingsTile(
                icon: FontAwesomeIcons.userShield,
                title: l10n.settingsData,
                subtitle: l10n.settingsDataSubtitle,
                onTap: () => _open(
                  context,
                  title: l10n.dataTitle,
                  sections: [
                    (
                      title: l10n.dataOnDeviceTitle,
                      body: l10n.dataOnDeviceBody,
                    ),
                    (title: l10n.dataWhyTitle, body: l10n.dataWhyBody),
                    (title: l10n.dataSentTitle, body: l10n.dataSentBody),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _SectionLabel(text: l10n.settingsLegal),
              _SettingsTile(
                icon: FontAwesomeIcons.lock,
                title: l10n.settingsPrivacy,
                onTap: () => _open(
                  context,
                  title: l10n.privacyTitle,
                  sections: [
                    (
                      title: l10n.privacyCollectedTitle,
                      body: l10n.privacyCollectedBody,
                    ),
                    (
                      title: l10n.privacyNotCollectedTitle,
                      body: l10n.privacyNotCollectedBody,
                    ),
                    (
                      title: l10n.privacyControllerTitle,
                      body: l10n.privacyControllerBody,
                    ),
                    (
                      title: l10n.privacyRightsTitle,
                      body: l10n.privacyRightsBody,
                    ),
                    (
                      title: l10n.privacyMinorsTitle,
                      body: l10n.privacyMinorsBody,
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.fileContract,
                title: l10n.settingsTerms,
                onTap: () => _open(
                  context,
                  title: l10n.termsTitle,
                  sections: [
                    (
                      title: l10n.termsPurposeTitle,
                      body: l10n.termsPurposeBody,
                    ),
                    (
                      title: l10n.termsNotEmergencyTitle,
                      body: l10n.termsNotEmergencyBody,
                    ),
                    (
                      title: l10n.termsHonestyTitle,
                      body: l10n.termsHonestyBody,
                    ),
                    (
                      title: l10n.termsChatbotTitle,
                      body: l10n.termsChatbotBody,
                    ),
                    (
                      title: l10n.termsLiabilityTitle,
                      body: l10n.termsLiabilityBody,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _SectionLabel(text: l10n.settingsAbout),
              const _AboutCard(),
            ],
          ),
        ),
      ),
    );
  }

  void _open(
    BuildContext context, {
    required String title,
    required List<LegalSection> sections,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(title: title, sections: sections),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final FaIconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: ExcludeSemantics(
        // Material plutôt qu'un Container coloré : un ListTile peint son fond
        // et son encre sur le Material le plus proche, qu'une simple
        // décoration masquerait.
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: IconUtils.buildIcon(
                icon,
                color: AppColors.primaryBlue,
                size: 18,
              ),
              title: Text(
                title,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 14.5),
              ),
              subtitle: subtitle == null
                  ? null
                  : Text(subtitle!, style: AppTextStyles.cardSubtitle),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailing != null)
                    Text(
                      trailing!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the running version — the first thing a support request needs.
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.aboutBody,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              return Text(
                info == null
                    ? '${l10n.settingsVersion} —'
                    : '${l10n.settingsVersion} ${info.version} (${info.buildNumber})',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
