import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../core/localization/report_enum_labels.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/report_provider.dart';

class Step4SummaryScreen extends StatelessWidget {
  const Step4SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final report = provider.currentReport;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.summaryTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.summarySubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 20),

          // Card 1: Contexte
          _buildSummaryCard(
            context,
            icon: FontAwesomeIcons.user,
            title: l10n.summarySectionContext,
            editLabel: l10n.actionEdit,
            onEdit: () => provider.setWizardStep(ReportProvider.stepWho),
            items: [
              _buildRow(
                l10n.summaryFor,
                report.whoFor?.label(l10n) ?? l10n.notSpecifiedMasculine,
              ),
              _buildRow(
                l10n.summaryAge,
                report.ageGroup?.label(l10n) ?? l10n.notSpecifiedMasculine,
              ),
              if (report.gender != null)
                _buildRow(l10n.summaryGender, report.gender!.label(l10n)),
            ],
          ),
          const SizedBox(height: 14),

          // Card 2: Problème
          _buildSummaryCard(
            context,
            icon: FontAwesomeIcons.triangleExclamation,
            title: l10n.summarySectionProblem,
            editLabel: l10n.actionEdit,
            onEdit: () =>
                provider.setWizardStep(ReportProvider.stepIncidentType),
            items: [
              _buildRow(
                l10n.summaryType,
                report.incidentType?.label(l10n) ?? l10n.notSpecifiedMasculine,
              ),
              _buildRow(
                l10n.summaryPlatform,
                report.platform?.label(l10n) ?? l10n.notSpecifiedFeminine,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Card 3: Détails & Preuves
          _buildSummaryCard(
            context,
            icon: FontAwesomeIcons.paperclip,
            title: l10n.summarySectionDetails,
            editLabel: l10n.actionEdit,
            onEdit: () => provider.setWizardStep(ReportProvider.stepEvidence),
            items: [
              _buildRow(
                l10n.summaryEvidence,
                report.evidenceFilePath != null
                    ? l10n.summaryEvidenceScreenshot
                    : (report.evidenceUrl != null &&
                              report.evidenceUrl!.isNotEmpty
                          ? l10n.summaryEvidenceLink
                          : l10n.summaryEvidenceNone),
              ),
              _buildRow(
                l10n.summaryAssistance,
                report.assistanceNeeded?.label(l10n) ??
                    l10n.notSpecifiedFeminine,
              ),
              if (report.assistanceType != null)
                _buildRow(
                  l10n.summaryAssistanceType,
                  report.assistanceType!.label(l10n),
                ),
              _buildRow(
                l10n.summaryUrgency,
                report.urgencyLevel?.label(l10n) ?? l10n.notSpecifiedFeminine,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required dynamic icon,
    required String title,
    required String editLabel,
    required VoidCallback onEdit,
    required List<Widget> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconUtils.buildIcon(icon, color: AppColors.primaryBlue, size: 16),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.cardTitle.copyWith(
                  color: AppColors.primaryBlue,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    editLabel,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.cardSubtitle.copyWith(fontSize: 13.5),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
