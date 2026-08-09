import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/report_provider.dart';
import '../../core/constants/app_contacts.dart';
import '../components/demo_notice.dart';
import '../components/glass_container.dart';

class ReportSuccessScreen extends StatelessWidget {
  final String referenceCode;

  const ReportSuccessScreen({super.key, required this.referenceCode});

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 40,
          bottom: 90,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Success Icon Circle
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.whatsappBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryBlue, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.25),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: IconUtils.buildIcon(
                  FontAwesomeIcons.circleCheck,
                  color: AppColors.primaryBlue,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.successTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle.copyWith(
                color: AppColors.primaryOrange,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.successBody,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenSubtitle.copyWith(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Reference Code Box
            GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              borderColor: AppColors.primaryBlue.withValues(alpha: 0.4),
              child: Column(
                children: [
                  Text(
                    l10n.referenceNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    referenceCode,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const DemoNotice(dense: true),
            if (!kBackendEnabled) const SizedBox(height: 16),

            // Info Card
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconUtils.buildIcon(
                    FontAwesomeIcons.circleInfo,
                    color: AppColors.primaryBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.keepReference,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.primaryBlue,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // CTA Button 1: "Voir les conseils"
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
              onPressed: () {
                reportProvider.setTab(2); // Switch to Ressources tab
              },
              icon: IconUtils.buildIcon(FontAwesomeIcons.lightbulb, size: 16),
              label: Text(
                l10n.seeAdvice,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // CTA Button 2: l10n.contactEmcHelpline
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
              onPressed: () {
                reportProvider.setTab(3); // Switch to Contact tab
              },
              icon: IconUtils.buildIcon(
                FontAwesomeIcons.headset,
                color: AppColors.primaryBlue,
                size: 16,
              ),
              label: Text(
                l10n.contactEmcHelpline,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
