import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/icon_utils.dart';
import '../l10n/app_localizations.dart';
import '../providers/report_provider.dart';
import 'main_navigation_screen.dart';
import 'onboarding_screen.dart';

/// Opening screen: the EMC Helpline logo fades in, holds, then hands over to
/// the app with a cross-fade.
///
/// The Android launch theme draws the same logo on white, so the native splash
/// and this one line up and the switch is invisible.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  /// How long the logo fades in.
  static const Duration fadeIn = Duration(milliseconds: 700);

  /// How long it stays before the app takes over.
  static const Duration hold = Duration(milliseconds: 550);

  /// Cross-fade from the logo to the app.
  static const Duration handover = Duration(milliseconds: 450);

  /// Total time before the app is interactive — useful to pump past in tests.
  static const Duration total = Duration(milliseconds: 1700);

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  /// `null` until the preference has been read, so the first frame after the
  /// logo cannot show the wrong screen and then swap.
  bool? _needsOnboarding;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashGate.fadeIn,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  // Barely perceptible: the logo settles rather than zooms.
  late final Animation<double> _scale = Tween<double>(
    begin: 0.92,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  Timer? _handoverTimer;
  bool _showApp = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _needsOnboarding = !context.read<ReportProvider>().hasSeenOnboarding;
    _handoverTimer = Timer(SplashGate.fadeIn + SplashGate.hold, () {
      if (mounted) setState(() => _showApp = true);
    });
  }

  @override
  void dispose() {
    _handoverTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnimatedSwitcher(
      duration: SplashGate.handover,
      child: _showApp
          ? (_needsOnboarding ?? false
                ? OnboardingScreen(
                    key: const ValueKey<String>('onboarding'),
                    onDone: () {
                      context.read<ReportProvider>().markOnboardingSeen();
                      setState(() => _needsOnboarding = false);
                    },
                  )
                : const MainNavigationScreen())
          : Scaffold(
              key: const ValueKey<String>('splash'),
              backgroundColor: Colors.white,
              body: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Image.asset(
                        'assets/images/emc.png',
                        semanticLabel: l10n.appTitle,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            IconUtils.buildIcon(
                              FontAwesomeIcons.shieldHalved,
                              color: AppColors.primaryBlue,
                              size: 72,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
