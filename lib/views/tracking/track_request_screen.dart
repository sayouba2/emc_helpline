import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/report_enum_labels.dart';
import '../../core/utils/icon_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_model.dart';
import '../../providers/report_provider.dart';
import '../components/glass_container.dart';
import '../components/scrollable_page.dart';

/// Looks a report up by the reference code handed to the user.
///
/// The lookup goes through [ReportProvider.findByReference], which reads this
/// session's history today and becomes a server call once the backend exists —
/// this screen needs no change when that happens.
class TrackRequestScreen extends StatefulWidget {
  const TrackRequestScreen({super.key});

  @override
  State<TrackRequestScreen> createState() => _TrackRequestScreenState();
}

class _TrackRequestScreenState extends State<TrackRequestScreen> {
  final TextEditingController _codeController = TextEditingController();

  ReportModel? _result;
  bool _searched = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _search() {
    final provider = Provider.of<ReportProvider>(context, listen: false);
    FocusScope.of(context).unfocus();
    setState(() {
      _searched = true;
      _result = provider.findByReference(_codeController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final code = _codeController.text.trim();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          l10n.trackRequest,
          style: AppTextStyles.cardTitle.copyWith(
            fontSize: 16,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ScrollablePage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.trackRequestSubtitle,
                style: AppTextStyles.screenSubtitle.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                l10n.trackRequestFieldLabel,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _codeController,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() => _searched = false),
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'REF-EMC-2026-123456',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(14.0),
                    child: FaIcon(
                      FontAwesomeIcons.hashtag,
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
              const SizedBox(height: 16),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primaryOrange.withValues(
                    alpha: 0.35,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: code.isEmpty ? null : _search,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(
                  l10n.trackRequestAction,
                  style: AppTextStyles.buttonText.copyWith(fontSize: 15),
                ),
              ),

              if (code.isEmpty && _searched) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.trackRequestEmptyField,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.dangerRedStrong,
                  ),
                ),
              ],

              if (_searched && code.isNotEmpty) ...[
                const SizedBox(height: 24),
                if (_result != null)
                  _buildResultCard(context, l10n, _result!)
                else
                  _buildNotFoundCard(l10n),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    AppLocalizations l10n,
    ReportModel report,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final createdAt = report.createdAt;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.primaryBlue.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconUtils.buildIcon(
                FontAwesomeIcons.circleCheck,
                color: AppColors.primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SelectableText(
                  report.referenceCode ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryBlue,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _buildRow(l10n.trackRequestStatus, l10n.reportStatusInProgress),
          if (createdAt != null)
            _buildRow(
              l10n.trackRequestFiledOn,
              DateFormat.yMMMMd(locale).add_Hm().format(createdAt),
            ),
          _buildRow(
            l10n.summaryType,
            report.incidentType?.label(l10n) ?? l10n.notSpecifiedMasculine,
          ),
          _buildRow(
            l10n.summaryUrgency,
            report.urgencyLevel?.label(l10n) ?? l10n.notSpecifiedFeminine,
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.emergencyBannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconUtils.buildIcon(
            FontAwesomeIcons.circleInfo,
            color: AppColors.primaryOrange,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.trackRequestNotFound,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.cardSubtitle.copyWith(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
