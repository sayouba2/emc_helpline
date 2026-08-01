import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/report_provider.dart';

class Step3EvidenceScreen extends StatefulWidget {
  const Step3EvidenceScreen({super.key});

  @override
  State<Step3EvidenceScreen> createState() => _Step3EvidenceScreenState();
}

class _Step3EvidenceScreenState extends State<Step3EvidenceScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ReportProvider>(context, listen: false);
    _urlController.text = provider.currentReport.evidenceUrl ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ReportProvider provider) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        provider.updateReport(
          evidenceImagePath: image.path,
          hasNoEvidence: false,
        );
      }
    } catch (e) {
      provider.updateReport(
        evidenceImagePath: "capture_ecran_preuve.png",
        hasNoEvidence: false,
      );
    }
  }

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
            "As-tu une preuve ?",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          const SizedBox(height: 8),
          Text(
            "Tu peux ajouter une capture d'écran ou un lien.",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 24),

          // Upload Card
          InkWell(
            onTap: () => _pickImage(provider),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: report.evidenceImagePath != null
                    ? AppColors.cardBg
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: report.evidenceImagePath != null
                      ? AppColors.primaryBlue
                      : AppColors.borderLight,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      shape: BoxShape.circle,
                    ),
                    child: FaIcon(
                      report.evidenceImagePath != null
                          ? FontAwesomeIcons.circleCheck
                          : FontAwesomeIcons.cloudArrowUp,
                      color: AppColors.primaryBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    report.evidenceImagePath != null
                        ? "Capture d'écran ajoutée"
                        : "Ajouter une capture",
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.evidenceImagePath != null
                        ? report.evidenceImagePath!.split('/').last
                        : "Image depuis la galerie ou capture d'écran.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.cardSubtitle,
                  ),
                  if (report.evidenceImagePath != null) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () {
                        provider.updateReport(evidenceImagePath: null);
                      },
                      icon: FaIcon(FontAwesomeIcons.trashCan, size: 13, color: AppColors.dangerRed),
                      label: const Text('Supprimer la capture', style: TextStyle(color: AppColors.dangerRed)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('OU', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),

          // URL Link Input
          Text(
            "Lien vers le contenu",
            style: AppTextStyles.cardTitle.copyWith(fontSize: 14.5),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            onChanged: (val) {
              provider.updateReport(
                evidenceUrl: val,
                hasNoEvidence: false,
              );
            },
            decoration: InputDecoration(
              hintText: "https://exemple.com/contenu",
              prefixIcon: Padding(
                padding: const EdgeInsets.all(14.0),
                child: FaIcon(FontAwesomeIcons.link, color: AppColors.primaryBlue, size: 16),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Button: "Je n'ai pas de preuve"
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: report.hasNoEvidence ? AppColors.primaryBlue : AppColors.borderLight,
                width: report.hasNoEvidence ? 2 : 1,
              ),
              backgroundColor: report.hasNoEvidence ? AppColors.cardBg : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              setState(() {
                _urlController.clear();
              });
              provider.updateReport(
                evidenceImagePath: null,
                evidenceUrl: null,
                hasNoEvidence: true,
              );
            },
            child: Text(
              "Je n'ai pas de preuve",
              style: AppTextStyles.buttonTextOutline,
            ),
          ),
        ],
      ),
    );
  }
}
