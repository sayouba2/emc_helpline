import 'dart:io';

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
import '../../components/step_layout.dart';

/// Evidence: one or more screenshots, and/or a link.
///
/// At least one of the two is required. An anonymous report carrying nothing to
/// look at cannot be triaged, and the online reporting portal asks for the same.
class StepEvidenceScreen extends StatefulWidget {
  const StepEvidenceScreen({super.key});

  @override
  State<StepEvidenceScreen> createState() => _Step3EvidenceScreenState();
}

class _Step3EvidenceScreenState extends State<StepEvidenceScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final report = Provider.of<ReportProvider>(
      context,
      listen: false,
    ).currentReport;
    _urlController.text = report.evidenceUrl ?? '';
    _descriptionController.text = report.description ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages(
    ReportProvider provider,
    AppLocalizations l10n,
  ) async {
    try {
      final images = await ImagePicker().pickMultiImage();
      if (images.isEmpty) return; // Selection cancelled.
      provider.addEvidenceFiles(images.map((image) => image.path));
    } catch (e) {
      // Never record a fake path: the user would believe a screenshot is
      // attached when none is.
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
    final paths = provider.currentReport.evidenceFilePaths;

    return StepLayout(
      title: l10n.evidenceQuestion,
      subtitle: l10n.evidenceSubtitle,
      children: [
        if (paths.isNotEmpty) ...[
          _buildThumbnails(provider, l10n, paths),
          const SizedBox(height: 14),
        ],

        _buildPickerCard(provider, l10n, paths.length),

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

        Text(
          l10n.evidenceLinkLabel,
          style: AppTextStyles.cardTitle.copyWith(fontSize: 14.5),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          // Une URL se lit de gauche à droite, y compris en arabe.
          textDirection: TextDirection.ltr,
          autocorrect: false,
          onChanged: (val) => provider.updateReport(evidenceUrl: val),
          decoration: InputDecoration(
            hintText: 'https://exemple.com/contenu',
            errorText: Validators.url(
              provider.currentReport.evidenceUrl,
            )?.text(l10n),
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

        const SizedBox(height: 20),

        _buildDescriptionField(provider, l10n),

        const SizedBox(height: 20),

        // Says why the step cannot be skipped, and where to go otherwise.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.emergencyBannerBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryOrange.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FaIcon(
                FontAwesomeIcons.circleInfo,
                color: AppColors.primaryOrange,
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.evidenceRequiredNote,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Always visible, so nothing typed here ever disappears — but only required
  /// while the report carries neither a screenshot nor a link.
  Widget _buildDescriptionField(
    ReportProvider provider,
    AppLocalizations l10n,
  ) {
    final report = provider.currentReport;
    final isRequired = !report.hasEvidence;
    final length = report.description?.trim().length ?? 0;
    final isTooShort =
        isRequired &&
        length > 0 &&
        !Validators.isDescriptionLongEnough(report.description);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                l10n.evidenceDescriptionLabel,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 14.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '· ${isRequired ? l10n.fieldRequired : l10n.fieldOptional}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
                color: isRequired
                    ? AppColors.primaryOrange
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          minLines: 4,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (val) => provider.updateReport(description: val),
          decoration: InputDecoration(
            hintText: l10n.evidenceDescriptionHint,
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
        if (isRequired) ...[
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              l10n.evidenceDescriptionCounter(
                length,
                Validators.minDescriptionLength,
              ),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isTooShort
                    ? AppColors.primaryOrange
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildThumbnails(
    ReportProvider provider,
    AppLocalizations l10n,
    List<String> paths,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.evidenceCount(paths.length),
          style: AppTextStyles.cardTitle.copyWith(fontSize: 13.5),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final path in paths) _buildThumbnail(provider, l10n, path),
          ],
        ),
      ],
    );
  }

  Widget _buildThumbnail(
    ReportProvider provider,
    AppLocalizations l10n,
    String path,
  ) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.bg,
                  alignment: Alignment.center,
                  child: const FaIcon(
                    FontAwesomeIcons.fileImage,
                    color: AppColors.primaryBlue,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: Semantics(
              button: true,
              label: l10n.evidenceRemoveOne,
              child: InkWell(
                onTap: () => provider.removeEvidenceFile(path),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.dangerRedStrong,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerCard(
    ReportProvider provider,
    AppLocalizations l10n,
    int count,
  ) {
    final hasAny = count > 0;

    return InkWell(
      onTap: () => _pickImages(provider, l10n),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: hasAny ? 18 : 32,
          horizontal: 20,
        ),
        decoration: BoxDecoration(
          color: hasAny ? AppColors.cardBg : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasAny ? AppColors.primaryBlue : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            FaIcon(
              hasAny
                  ? FontAwesomeIcons.circlePlus
                  : FontAwesomeIcons.cloudArrowUp,
              color: AppColors.primaryBlue,
              size: hasAny ? 22 : 28,
            ),
            const SizedBox(height: 10),
            Text(
              hasAny ? l10n.evidenceAddMore : l10n.evidenceAddScreenshots,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
