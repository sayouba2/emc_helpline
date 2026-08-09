import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../l10n/app_localizations.dart';

/// Covers the round trip between "Envoyer" and the confirmation.
///
/// Sending a report is the moment a child is most likely to wonder whether
/// anything happened at all, so the wait is shown rather than left blank.
class SendingScreen extends StatefulWidget {
  const SendingScreen({super.key});

  @override
  State<SendingScreen> createState() => _SendingScreenState();
}

class _SendingScreenState extends State<SendingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  late final Animation<double> _halo = Tween<double>(
    begin: 0.9,
    end: 1.35,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Expanding halo behind the shield.
                    ScaleTransition(
                      scale: _halo,
                      child: FadeTransition(
                        opacity: Tween<double>(
                          begin: 0.35,
                          end: 0.0,
                        ).animate(_controller),
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 108,
                      height: 108,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.primaryOrange,
                        backgroundColor: AppColors.border,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconUtils.buildIcon(
                        FontAwesomeIcons.paperPlane,
                        color: AppColors.primaryOrange,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.sendingTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.sendingBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
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
