import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/report_provider.dart';
import '../chatbot/emc_chatbot_screen.dart';
import '../components/glass_container.dart';
import '../components/scrollable_page.dart';

class ReportSuccessScreen extends StatelessWidget {
  final String referenceCode;

  const ReportSuccessScreen({super.key, required this.referenceCode});

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ScrollablePage(
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
            if (reportProvider.currentReport.ageGroup?.isChatbotEligible ??
                false) ...[
              const SizedBox(height: 16),
              _buildChatbotCard(context, l10n),
            ],

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

  /// The chatbot is designed for the 12+ audience, so it is only offered to
  /// them — and only here, where the wait for a human answer starts.
  Widget _buildChatbotCard(BuildContext context, AppLocalizations l10n) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.primaryOrange.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: IconUtils.buildIcon(
                  FontAwesomeIcons.robot,
                  color: AppColors.primaryOrange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.successChatbotTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.successChatbotBody,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const EmcChatbotScreen(),
                ),
              ),
              icon: IconUtils.buildIcon(
                FontAwesomeIcons.comments,
                size: 15,
                color: Colors.white,
              ),
              label: Text(
                l10n.chatbotOpenButton,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
