import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Shows a discreet bar when a case moves while the app is open.
///
/// Android only draws a notification itself when the app is in the background;
/// in the foreground the message reaches the app and is shown by nobody. So a
/// status change arriving while its author sat on the tracking screen produced
/// nothing at all — the one moment they were certainly watching.
///
/// Wrapped around the whole app rather than dropped on one screen: the message
/// can land whatever the user is doing, including mid-report.
class ForegroundUpdateBanner extends StatefulWidget {
  const ForegroundUpdateBanner({
    super.key,
    required this.updates,
    required this.child,
  });

  /// Injectable so the behaviour can be tested without Firebase.
  final Stream<void> updates;
  final Widget child;

  @override
  State<ForegroundUpdateBanner> createState() => _ForegroundUpdateBannerState();
}

class _ForegroundUpdateBannerState extends State<ForegroundUpdateBanner> {
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.updates.listen((_) => _show());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _show() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // Says no more than the notification does. Being in the app is not
          // being alone with it — the phone may well be shared, which is the
          // situation this whole product is built around.
          content: Text(l10n.notifyInAppUpdate),
          backgroundColor: AppColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
