import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/report_enums.dart';
import '../../../providers/report_provider.dart';
import '../../components/glass_container.dart';
import '../../components/interactive_card.dart';

class Step1WhoScreen extends StatefulWidget {
  const Step1WhoScreen({super.key});

  @override
  State<Step1WhoScreen> createState() => _Step1WhoScreenState();
}

class _Step1WhoScreenState extends State<Step1WhoScreen> {
  late TextEditingController _pseudoController;

  @override
  void initState() {
    super.initState();
    final report = Provider.of<ReportProvider>(
      context,
      listen: false,
    ).currentReport;
    _pseudoController = TextEditingController(text: report.pseudo ?? '');
  }

  @override
  void dispose() {
    _pseudoController.dispose();
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
    setState(() {
      _pseudoController.text = chosen;
    });
    Provider.of<ReportProvider>(
      context,
      listen: false,
    ).updateReport(pseudo: chosen);
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final l10n = AppLocalizations.of(context);
    final currentSelection = reportProvider.currentReport.whoFor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.whoNeedsHelp,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle.copyWith(
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.whoNeedsHelpSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Les deux options côte à côte : pleine largeur, elles se lisaient
          // comme des sections plutôt que comme un choix à faire.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildOptionCard(
                    context,
                    title: l10n.whoForSelf,
                    subtitle: l10n.whoForSelfSubtitle,
                    icon: FontAwesomeIcons.user,
                    isSelected: currentSelection == WhoFor.self,
                    onTap: () {
                      reportProvider.updateReport(whoFor: WhoFor.self);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOptionCard(
                    context,
                    title: l10n.whoForSomeoneElse,
                    subtitle: l10n.whoForSomeoneElseSubtitle,
                    icon: FontAwesomeIcons.userGroup,
                    isSelected: currentSelection == WhoFor.someoneElse,
                    onTap: () {
                      reportProvider.updateReport(whoFor: WhoFor.someoneElse);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Anonymity & Pseudonym Card (Garantie Anonymat dès le premier contact)
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.anonymityTitle,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            l10n.anonymitySubtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _pseudoController,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.pseudoHint,
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
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
                  onChanged: (val) {
                    reportProvider.updateReport(pseudo: val);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.pseudoInfo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required dynamic icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InteractiveCard(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          borderColor: isSelected ? AppColors.primaryBlue : null,
          borderWidth: isSelected ? 2.5 : 1,
          child: Column(
            children: [
              // A radio marker makes it read as a choice, which two big cards
              // side by side otherwise do not.
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: isSelected ? AppColors.primaryBlue : AppColors.border,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.whatsappBg : AppColors.bg,
                  shape: BoxShape.circle,
                ),
                child: IconUtils.buildIcon(
                  icon,
                  size: 20,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 14.5,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.cardSubtitle.copyWith(
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
