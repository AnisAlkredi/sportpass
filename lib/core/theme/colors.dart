import 'package:flutter/material.dart';

/// Freeze V1 color tokens.
class C {
  C._();

  // ━━━ BRAND ━━━
  static const Color navy = Color(0xFF0A1628);
  static const Color navyLight = Color(0xFF10213A);
  static const Color cyan = Color(0xFF00E5A0);
  static const Color cyanLight = Color(0xFF54F4C2);
  static const Color green = Color(0xFF1FC16B);
  static const Color gold = Color(0xFFFFB800);
  static const Color red = Color(0xFFFF5A5A);
  static const Color purple = Color(0xFF7A5CFF);

  // ━━━ SURFACES ━━━
  static const Color bg = Color(0xFF0A1628);
  static const Color surface = Color(0xFF13233A);
  static const Color surfaceAlt = Color(0xFF1A2E4A);
  static const Color card = Color(0xCC13233A);
  static const Color cardHover = Color(0xFF1D3453);
  static const Color border = Color(0xFF274265);
  static const Color borderGlow = Color(0xFF00E5A0);

  // ━━━ TEXT ━━━
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCCD8E6);
  static const Color textMuted = Color(0xFF8FA6BF);

  // ━━━ SEMANTIC ━━━
  static const Color success = green;
  static const Color error = red;
  static const Color warning = gold;
  static const Color info = cyan;

  // ━━━ GRADIENTS ━━━
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1628), Color(0xFF153154), Color(0xFF0A1628)],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5A0), Color(0xFF00C98C)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB800), Color(0xFFFF9800)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1FC16B), Color(0xFF149B54)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7A5CFF), Color(0xFF5F45D8)],
  );

  static const LinearGradient walletGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF17315A), Color(0xFF0E5B55), Color(0xFF00BFA5)],
  );

  // ━━━ TIER SYSTEM (legacy display only) ━━━
  static Color tierColor(String tier) => switch (tier.toUpperCase()) {
        'A' => gold,
        'B' => cyan,
        'C' => textMuted,
        _ => textMuted,
      };

  static LinearGradient tierGradient(String tier) =>
      switch (tier.toUpperCase()) {
        'A' => goldGradient,
        'B' => cyanGradient,
        'C' =>
          const LinearGradient(colors: [Color(0xFF8FA6BF), Color(0xFF6F87A3)]),
        _ =>
          const LinearGradient(colors: [Color(0xFF8FA6BF), Color(0xFF6F87A3)]),
      };

  static String tierLabel(String tier) => switch (tier.toUpperCase()) {
        'A' => 'بريميوم',
        'B' => 'ستاندرد',
        'C' => 'أساسي',
        _ => 'أساسي',
      };
}
