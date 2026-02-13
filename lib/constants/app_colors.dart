import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Colors ──
  static const Color rowanBrown = Color(0xFF531017);
  static const Color rowanBrownLight = Color(0xFF801525);
  static const Color rowanBrownDark = Color(0xFF3A0B10);
  static const Color rowanGold = Color(0xFFFFCC00);
  static const Color rowanGoldLight = Color(0xFFFFE066);
  static const Color rowanGoldDark = Color(0xFFE6B800);

  // ── Surfaces ──
  static const Color cream = Color(0xFFFDFBF7);
  static const Color creamDark = Color(0xFFEFE6D5);
  static const Color white = Colors.white;
  static const Color cardBg = Colors.white;
  static const Color surfaceLight = Color(0xFFF8F6F2);
  static const Color surfaceMedium = Color(0xFFF0ECE4);

  // ── Text ──
  static const Color darkText = Color(0xFF1A1A2E);
  static const Color bodyText = Color(0xFF333333);
  static const Color subtitleText = Color(0xFF666666);
  static const Color lightText = Color(0xFF999999);

  // ── Status ──
  static const Color success = Color(0xFF2ECC71);
  static const Color successDark = Color(0xFF27AE60);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorDark = Color(0xFFC0392B);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningDark = Color(0xFFE67E22);
  static const Color info = Color(0xFF3498DB);
  static const Color infoDark = Color(0xFF2980B9);

  // ── Shimmer ──
  static const Color shimmerBase = Color(0xFFE8E4DE);
  static const Color shimmerHighlight = Color(0xFFF5F2ED);

  // ── Glassmorphism ──
  static Color glassWhite = Colors.white.withAlpha(38);
  static Color glassBorder = Colors.white.withAlpha(51);

  // ── Gradients ──
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cream, creamDark],
  );

  static const LinearGradient brownGradient = LinearGradient(
    colors: [rowanBrown, rowanBrownLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brownDarkGradient = LinearGradient(
    colors: [Color(0xFF6B1420), rowanBrown, rowanBrownDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [rowanGold, rowanGoldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, errorDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadow Presets ──
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withAlpha(10),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withAlpha(15),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withAlpha(5),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get bottomBarShadow => [
        BoxShadow(
          color: Colors.black.withAlpha(8),
          blurRadius: 12,
          offset: const Offset(0, -3),
        ),
      ];
}
