import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// intl exporte son propre TextDirection, qui masquerait celui de Flutter.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/report_enum_labels.dart';
import '../../core/utils/icon_utils.dart';
import '../../core/utils/reference_code.dart';
import '../../l10n/app_localizations.dart';
import '../../models/tracking_outcome.dart';
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

  TrackingOutcome? _outcome;
  bool _isSearching = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final provider = Provider.of<ReportProvider>(context, listen: false);
    FocusScope.of(context).unfocus();
    final typed = _codeController.text;

    setState(() => _isSearching = true);
    final outcome = await provider.lookupReference(typed);
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _outcome = outcome;
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
                onChanged: (_) => setState(() => _outcome = null),
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: ReferenceCode.example,
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
                onPressed: code.isEmpty || _isSearching ? null : _search,
                icon: _isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search_rounded, size: 18),
                label: Text(
                  _isSearching
                      ? l10n.trackRequestSearching
                      : l10n.trackRequestAction,
                  style: AppTextStyles.buttonText.copyWith(fontSize: 15),
                ),
              ),

              if (code.isEmpty && _outcome != null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.trackRequestEmptyField,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.dangerRedStrong,
                  ),
                ),
              ],

              ...switch (_outcome) {
                null => const <Widget>[],
                TrackingFound(:final report) => [
                  const SizedBox(height: 24),
                  _buildResultCard(context, l10n, report),
                ],
                TrackingMalformed() => [
                  const SizedBox(height: 24),
                  _buildNoticeCard(l10n.trackRequestMalformed),
                ],
                TrackingNotFound() => [
                  const SizedBox(height: 24),
                  _buildNoticeCard(l10n.trackRequestNotFound),
                ],
                // Kept apart from "no such case": the report has not gone
                // anywhere, and a child must not be told otherwise because a
                // lookup failed.
                TrackingUnavailable() => [
                  const SizedBox(height: 24),
                  _buildNoticeCard(
                    l10n.trackRequestUnavailable,
                    isProblem: true,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSearching ? null : _search,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.primaryBlue,
                    ),
                    label: Text(
                      l10n.trackRequestRetry,
                      style: AppTextStyles.buttonTextOutline.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    AppLocalizations l10n,
    TrackedReport report,
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
                  // Le code se lit caractère par caractère : il reste LTR.
                  textDirection: TextDirection.ltr,
                  report.referenceCode,
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
          _buildRow(
            l10n.trackRequestStatus,
            // A status this build does not know means a newer backend against
            // an older app. Better a neutral sentence than a guess.
            report.status?.label(l10n) ?? l10n.trackStatusUnknown,
          ),
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

  Widget _buildNoticeCard(String message, {bool isProblem = false}) {
    final accent = isProblem
        ? AppColors.dangerRedStrong
        : AppColors.primaryOrange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.emergencyBannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconUtils.buildIcon(
            isProblem
                ? FontAwesomeIcons.cloudArrowDown
                : FontAwesomeIcons.circleInfo,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
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
