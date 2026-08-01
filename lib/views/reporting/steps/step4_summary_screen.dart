import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../providers/report_provider.dart';

class Step4SummaryScreen extends StatelessWidget {
  const Step4SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final report = provider.currentReport;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Vérifie ton signalement",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          const SizedBox(height: 8),
          Text(
            "Tu peux corriger avant l'envoi.",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 20),

          // Card 1: Contexte
          _buildSummaryCard(
            context,
            icon: FontAwesomeIcons.user,
            title: "Contexte",
            onEdit: () => provider.setWizardStep(0),
            items: [
              _buildRow("Pour", report.whoFor ?? "Non précisé"),
              _buildRow("Âge", report.ageRange ?? "Non précisé"),
              if (report.gender != null) _buildRow("Genre", report.gender!),
            ],
          ),
          const SizedBox(height: 14),

          // Card 2: Problème
          _buildSummaryCard(
            context,
            icon: FontAwesomeIcons.triangleExclamation,
            title: "Problème",
            onEdit: () => provider.setWizardStep(3),
            items: [
              _buildRow("Type", report.incidentType ?? "Non précisé"),
              _buildRow("Plateforme", report.platform ?? "Non précisée"),
            ],
          ),
          const SizedBox(height: 14),

          // Card 3: Détails & Preuves
          _buildSummaryCard(
            context,
            icon: FontAwesomeIcons.paperclip,
            title: "Détails & Preuves",
            onEdit: () => provider.setWizardStep(5),
            items: [
              _buildRow(
                "Preuve",
                report.evidenceImagePath != null
                    ? "1 capture d'écran"
                    : (report.evidenceUrl != null && report.evidenceUrl!.isNotEmpty
                        ? "Lien web fourni"
                        : "Aucune"),
              ),
              _buildRow(
                "Aide",
                report.wantsAssistance ?? "Non précisée",
              ),
              if (report.assistanceType != null)
                _buildRow("Type d'aide", report.assistanceType!),
              _buildRow("Urgence", report.urgency ?? "Non précisée"),
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
    required VoidCallback onEdit,
    required List<Widget> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
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
                    "Modifier",
                    style: TextStyle(
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
          Text(label, style: AppTextStyles.cardSubtitle.copyWith(fontSize: 13.5)),
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
