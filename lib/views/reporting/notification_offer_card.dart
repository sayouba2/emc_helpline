import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/backend/case_notifications.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/report_provider.dart';
import '../components/glass_container.dart';

/// Offers to notify the user when their case moves.
///
/// Shown where the reference number is, because that is the only moment the app
/// knows the code — it is never written down. The offer carries its warning
/// *above* the button, not in small print underneath: a notification from this
/// app appearing on a shared phone is a real risk for the person using it, and
/// they are the only one who can weigh it.
class NotificationOfferCard extends StatefulWidget {
  const NotificationOfferCard({
    super.key,
    required this.referenceCode,
    this.notifications,
  });

  final String referenceCode;

  /// Injectable so the card can be exercised without Firebase.
  final CaseNotifications? notifications;

  @override
  State<NotificationOfferCard> createState() => _NotificationOfferCardState();
}

enum _Offer { pending, working, accepted, refused }

class _NotificationOfferCardState extends State<NotificationOfferCard> {
  _Offer _state = _Offer.pending;

  Future<void> _accept() async {
    final provider = Provider.of<ReportProvider>(context, listen: false);
    final language = Localizations.localeOf(context).languageCode;

    setState(() => _state = _Offer.working);
    final notifications = widget.notifications ?? CaseNotifications();
    final granted = await notifications.enableFor(
      widget.referenceCode,
      language,
    );
    if (!mounted) return;

    await provider.setNotificationsEnabled(granted);
    if (!mounted) return;
    setState(() => _state = granted ? _Offer.accepted : _Offer.refused);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.primaryBlue.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconUtils.buildIcon(
                FontAwesomeIcons.bell,
                color: AppColors.primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.notifyOfferTitle,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_state == _Offer.accepted)
            Text(l10n.notifyEnabled, style: _bodyStyle)
          else ...[
            Text(l10n.notifyOfferBody, style: _bodyStyle),
            const SizedBox(height: 12),
            // Above the button on purpose. Someone deciding this needs to have
            // read it, not to be able to say they could have.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.emergencyBannerBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconUtils.buildIcon(
                    FontAwesomeIcons.triangleExclamation,
                    color: AppColors.primaryOrange,
                    size: 15,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.notifyWarning,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_state == _Offer.refused) ...[
              const SizedBox(height: 10),
              Text(
                l10n.notifyRefused,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: AppColors.dangerRedStrong,
                ),
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _state == _Offer.working ? null : _accept,
              icon: _state == _Offer.working
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconUtils.buildIcon(
                      FontAwesomeIcons.bell,
                      color: AppColors.primaryBlue,
                      size: 15,
                    ),
              label: Text(
                l10n.notifyEnable,
                style: AppTextStyles.buttonTextOutline.copyWith(
                  fontSize: 13.5,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const TextStyle _bodyStyle = TextStyle(
    fontSize: 12.5,
    height: 1.35,
    color: AppColors.textSecondary,
  );
}
