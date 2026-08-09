import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/report_enum_labels.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
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

  Future<void> _pickImage(
    ReportProvider provider,
    AppLocalizations l10n,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return; // Sélection annulée par l'utilisateur.
      provider.updateReport(evidenceFilePath: image.path, hasNoEvidence: false);
    } catch (e) {
      // Ne jamais enregistrer de preuve factice : l'utilisateur croirait avoir
      // joint une capture qui n'existe pas.
      debugPrint('Evidence image picking failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.evidencePickFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
            l10n.evidenceQuestion,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.evidenceSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 24),

          // Upload Card
          InkWell(
            onTap: () => _pickImage(provider, l10n),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: report.evidenceFilePath != null
                    ? AppColors.cardBg
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: report.evidenceFilePath != null
                      ? AppColors.primaryBlue
                      : AppColors.border,
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
                    decoration: const BoxDecoration(
                      color: AppColors.cardBg,
                      shape: BoxShape.circle,
                    ),
                    child: FaIcon(
                      report.evidenceFilePath != null
                          ? FontAwesomeIcons.circleCheck
                          : FontAwesomeIcons.cloudArrowUp,
                      color: AppColors.primaryBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    report.evidenceFilePath != null
                        ? l10n.evidenceAdded
                        : l10n.evidenceAdd,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.evidenceFilePath != null
                        ? report.evidenceFilePath!.split('/').last
                        : l10n.evidenceAddHint,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.cardSubtitle,
                  ),
                  if (report.evidenceFilePath != null) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () {
                        provider.updateReport(evidenceFilePath: null);
                      },
                      icon: const FaIcon(
                        FontAwesomeIcons.trashCan,
                        size: 13,
                        color: AppColors.dangerRed,
                      ),
                      label: Text(
                        l10n.evidenceRemove,
                        style: const TextStyle(
                          color: AppColors.dangerRedStrong,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.separatorOr,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),

          // URL Link Input
          Text(
            l10n.evidenceLinkLabel,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 14.5),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            onChanged: (val) {
              provider.updateReport(evidenceUrl: val, hasNoEvidence: false);
            },
            decoration: InputDecoration(
              hintText: "https://exemple.com/contenu",
              errorText: Validators.url(report.evidenceUrl)?.text(l10n),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(14.0),
                child: FaIcon(
                  FontAwesomeIcons.link,
                  color: AppColors.primaryBlue,
                  size: 16,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Button: "Je n'ai pas de preuve"
          Semantics(
            selected: report.hasNoEvidence,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: report.hasNoEvidence
                      ? AppColors.primaryBlue
                      : AppColors.border,
                  width: report.hasNoEvidence ? 2 : 1,
                ),
                backgroundColor: report.hasNoEvidence
                    ? AppColors.cardBg
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                setState(() {
                  _urlController.clear();
                });
                provider.updateReport(
                  evidenceFilePath: null,
                  evidenceUrl: null,
                  hasNoEvidence: true,
                );
              },
              child: Text(
                l10n.evidenceNone,
                style: AppTextStyles.buttonTextOutline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
