import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A translucent card.
///
/// The real backdrop blur is opt-in via [frosted]. It only reads as glass when
/// something non-uniform scrolls behind — in practice just the bottom
/// navigation bar. Everywhere else the card sits on a flat background, where a
/// `BackdropFilter` under an 85%-opaque fill costs a full-screen gaussian blur
/// per card for no visible difference. There were about thirty of them alive at
/// once before this became a flag.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final bool frosted;
  final double blur;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.frosted = false,
    this.blur = 12.0,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.padding,
    this.margin,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(20);

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: borderColor ?? AppColors.border.withValues(alpha: 0.8),
          width: borderWidth,
        ),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    // Without a blur there is nothing to clip: the decoration already rounds
    // its own background and border. Dropping the ClipRRect removes a clip —
    // and the save layer it can force — from every card on screen.
    if (!frosted) {
      return margin == null ? card : Container(margin: margin, child: card);
    }

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: card,
        ),
      ),
    );
  }
}
