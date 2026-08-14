import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/report_enum_labels.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/report_enums.dart';
import '../../../providers/report_provider.dart';
import '../../chatbot/emc_chatbot_screen.dart';
import '../../components/choice_card.dart';
import '../../components/glass_container.dart';
import '../../components/step_layout.dart';

/// Step 1 — the age bracket, which also decides whether the chatbot is offered.
class StepAgeScreen extends StatelessWidget {
  const StepAgeScreen({super.key});

  static IconData _iconFor(AgeGroup group) => switch (group) {
    AgeGroup.child => Icons.child_care_rounded,
    AgeGroup.teen => Icons.sentiment_satisfied_alt_rounded,
    AgeGroup.adult => Icons.person_rounded,
    AgeGroup.undisclosed => Icons.help_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final selected = provider.currentReport.ageGroup;

    return StepLayout(
      title: l10n.ageQuestion,
      subtitle: l10n.ageSubtitle,
      children: [
        for (final option in AgeGroup.values)
          ChoiceCard(
            label: option.label(l10n),
            icon: _iconFor(option),
            isSelected: selected == option,
            onTap: () => provider.updateReport(ageGroup: option),
          ),
        if (selected?.isChatbotEligible ?? false) ...[
          const SizedBox(height: 8),
          _ChatbotBanner(l10n: l10n),
        ],
      ],
    );
  }
}

/// Offered from 13 up: the assistant is written for that audience.
class _ChatbotBanner extends StatelessWidget {
  const _ChatbotBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.primaryOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: IconUtils.buildIcon(
                  FontAwesomeIcons.robot,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.chatbotBannerTitle,
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
            l10n.chatbotBannerBody,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          // Un ElevatedButton.icon place l'icône et le libellé dans une Row
          // sur laquelle on ne peut rien contraindre : à 2× la police, le
          // libellé débordait. Une Row explicite laisse le texte se replier.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconUtils.buildIcon(
                    FontAwesomeIcons.comments,
                    size: 15,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      l10n.chatbotOpenButton,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
