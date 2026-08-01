import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF1E3A8A); // Deep Royal Blue
  static const Color primaryOrange = Color(0xFFEA580C); // Vibrant Warm Amber / Orange
  static const Color accentCyan = Color(0xFF06B6D4); // Cyan Accent
  static const Color accentPurple = Color(0xFF8B5CF6); // Purple Glow Accent

  // Legacy Aliases for Step Compatibility
  static const Color cardBg = cardBgLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color dangerRedBg = dangerRedBgLight;
  static const Color emergencyBannerBg = emergencyBannerBgLight;

  // Light Theme Surfaces
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardBgLight = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Dark Theme Surfaces
  static const Color bgDark = Color(0xFF0B0F19);
  static const Color cardBgDark = Color(0xFF161E2E);
  static const Color borderDark = Color(0xFF26334D);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Emergency & Status Colors
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color dangerRedBgLight = Color(0xFFFEE2E2);
  static const Color dangerRedBgDark = Color(0xFF451A1A);
  static const Color emergencyBannerBgLight = Color(0xFFFFF7ED);
  static const Color emergencyBannerBgDark = Color(0xFF2A1B0E);

  // Social Media Brand Palettes
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color whatsappBgLight = Color(0xFFDCFCE7);
  static const Color whatsappBgDark = Color(0xFF064E3B);

  static const Color instagramPink = Color(0xFFE1306C);
  static const Color instagramBgLight = Color(0xFFFCE7F3);
  static const Color instagramBgDark = Color(0xFF831843);

  static const Color tiktokDark = Color(0xFF000000);
  static const Color tiktokBgLight = Color(0xFFF1F5F9);
  static const Color tiktokBgDark = Color(0xFF1E293B);

  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color facebookBgLight = Color(0xFFDBEAFE);
  static const Color facebookBgDark = Color(0xFF1E3A8A);

  static const Color gamingPurple = Color(0xFF7C3AED);
  static const Color gamingBgLight = Color(0xFFF3E8FF);
  static const Color gamingBgDark = Color(0xFF4C1D95);

  static const Color messengerBlue = Color(0xFF0084FF);
  static const Color messengerBgLight = Color(0xFFE0F2FE);
  static const Color messengerBgDark = Color(0xFF0C4A6E);

  // Glassmorphism Overlays
  static const Color glassWhite = Color(0x3DFFFFFF);
  static const Color glassBorderWhite = Color(0x66FFFFFF);
  static const Color glassDark = Color(0x4D161E2E);
  static const Color glassBorderDark = Color(0x4D38BDF8);

  // Gradients
  static const LinearGradient heroGradientLight = LinearGradient(
    colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4), Colors.white],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradientDark = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0B0F19)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeCtaGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonBlueGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dynamic Theme Helpers
  static Color getBg(bool isDark) => isDark ? bgDark : bgLight;
  static Color getCardBg(bool isDark) => isDark ? cardBgDark : cardBgLight;
  static Color getBorder(bool isDark) => isDark ? borderDark : borderLight;
  static Color getTextPrimary(bool isDark) => isDark ? textPrimaryDark : textPrimaryLight;
  static Color getTextSecondary(bool isDark) => isDark ? textSecondaryDark : textSecondaryLight;
}
