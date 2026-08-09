import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/report_enum_labels.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/report_provider.dart';
import '../../components/glass_container.dart';

/// How to reach the user back.
///
/// Only shown to people who asked to be accompanied — the wizard skips it
/// otherwise — so the nickname and the phone number are both required here.
/// Nothing on this screen asks for a real name.
class Step3ContactScreen extends StatefulWidget {
  const Step3ContactScreen({super.key});

  @override
  State<Step3ContactScreen> createState() => _Step3ContactScreenState();
}

class _Step3ContactScreenState extends State<Step3ContactScreen> {
  final TextEditingController _pseudoController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final report = Provider.of<ReportProvider>(
      context,
      listen: false,
    ).currentReport;
    _pseudoController.text = report.pseudo ?? '';
    _phoneController.text = report.contactPhone ?? '';
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _generateRandomPseudo(AppLocalizations l10n) {
    final suggestions = [
      l10n.pseudoSuggestion1,
      l10n.pseudoSuggestion2,
      l10n.pseudoSuggestion3,
      l10n.pseudoSuggestion4,
      l10n.pseudoSuggestion5,
      l10n.pseudoSuggestion6,
      l10n.pseudoSuggestion7,
    ];
    final chosen = suggestions[Random().nextInt(suggestions.length)];
    setState(() => _pseudoController.text = chosen);
    Provider.of<ReportProvider>(
      context,
      listen: false,
    ).updateReport(pseudo: chosen);
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
            l10n.contactQuestion,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.contactSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 20),

          // Pseudonym — moved here from the first step, because this is where
          // it is used: the team calls back using it, never a real name.
          GlassContainer(
            padding: const EdgeInsets.all(18),
            borderColor: AppColors.primaryOrange.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: IconUtils.buildIcon(
                        FontAwesomeIcons.userSecret,
                        color: AppColors.primaryOrange,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.anonymityTitle,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.contactRequiredNote,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _pseudoController,
                  autocorrect: false,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.pseudoHint,
                    filled: true,
                    fillColor: AppColors.bg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryOrange,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (val) => provider.updateReport(pseudo: val),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      backgroundColor: AppColors.primaryOrange.withValues(
                        alpha: 0.1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _generateRandomPseudo(l10n),
                    icon: const Text('🎲', style: TextStyle(fontSize: 12)),
                    label: Text(
                      l10n.pseudoAuto,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildTextField(
            controller: _phoneController,
            label: l10n.fieldPhone,
            hint: l10n.fieldPhoneHint,
            icon: FontAwesomeIcons.phone,
            keyboardType: TextInputType.phone,
            errorText: Validators.phone(report.contactPhone)?.text(l10n),
            onChanged: (val) => provider.updateReport(contactPhone: val),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                IconUtils.buildIcon(
                  FontAwesomeIcons.shieldHalved,
                  color: AppColors.primaryBlue,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.contactConfidentialNote,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required dynamic icon,
    Color? iconColor,
    TextInputType? keyboardType,
    String? errorText,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.cardTitle.copyWith(fontSize: 13.5)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12.0),
              child: IconUtils.buildIcon(
                icon,
                color: iconColor ?? AppColors.primaryBlue,
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
      ],
    );
  }
}
