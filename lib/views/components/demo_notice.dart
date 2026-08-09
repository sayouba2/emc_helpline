import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_contacts.dart';
import '../../core/utils/icon_utils.dart';
import '../../l10n/app_localizations.dart';

/// Warns that reports go nowhere yet.
///
/// The app promises "CONFIDENTIEL & SÉCURISÉ", says "Signalement envoyé" and
/// hands out a reference number, while `submitReport` only appends to a list in
/// memory. For a child-protection helpline that gap is the most dangerous thing
/// in the product, so it is stated plainly until [kBackendEnabled] is set at
/// build time.
///
/// Renders nothing once a backend exists.
class DemoNotice extends StatelessWidget {
  const DemoNotice({super.key, this.dense = false});

  /// A compact single-block variant for screens that already carry a lot.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (kBackendEnabled) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(dense ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.emergencyBannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryOrange, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconUtils.buildIcon(
            FontAwesomeIcons.triangleExclamation,
            color: AppColors.primaryOrange,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.demoNoticeTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryOrange,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dense ? l10n.demoSuccessNotice : l10n.demoNoticeBody,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
