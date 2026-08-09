import 'package:flutter/material.dart';

/// The app ships a single light theme. Every colour here is final — there is no
/// dark counterpart and no `isDark` branching left in the widget tree.
class AppColors {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF1E3A8A); // Deep Royal Blue

  /// Brand orange, darkened from #EA580C to reach WCAG AA. The original tone
  /// only scored 3.56:1 against white — fine for icons and large headings, but
  /// short of the 4.5:1 that body-size labels and white-on-orange buttons need.
  /// This one scores 5.18:1.
  static const Color primaryOrange = Color(0xFFC2410C);

  /// The original, brighter orange. Decorative use only — tinted fills, glows
  /// and borders, which are graphical objects and only need 3:1.
  static const Color primaryOrangeBright = Color(0xFFEA580C);

  // Surfaces
  static const Color bg = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  // Emergency & Status Colors
  /// Reserved for icons and fills. For red *text*, use [dangerRedStrong].
  static const Color dangerRed = Color(0xFFEF4444);

  /// 6.47:1 against white, so red labels stay readable.
  static const Color dangerRedStrong = Color(0xFFB91C1C);
  static const Color dangerRedBg = Color(0xFFFEE2E2);
  static const Color emergencyBannerBg = Color(0xFFFFF7ED);

  // Social Media Brand Palettes
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color whatsappBg = Color(0xFFDCFCE7);

  static const Color instagramPink = Color(0xFFE1306C);
  static const Color instagramBg = Color(0xFFFCE7F3);

  static const Color tiktokDark = Color(0xFF000000);
  static const Color tiktokBg = Color(0xFFF1F5F9);

  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color facebookBg = Color(0xFFDBEAFE);

  static const Color gamingPurple = Color(0xFF7C3AED);
  static const Color gamingBg = Color(0xFFF3E8FF);

  static const Color messengerBlue = Color(0xFF0084FF);
  static const Color messengerBg = Color(0xFFE0F2FE);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4), Colors.white],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Both stops clear 4.5:1 against white, so the label on the main call to
  /// action stays readable across the whole sweep.
  static const LinearGradient orangeCtaGradient = LinearGradient(
    colors: [Color(0xFFC2410C), Color(0xFF9A3412)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
