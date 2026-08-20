import 'package:flutter/material.dart';

/// Official Rice University Brand Colors (brand.rice.edu)
class RiceColors {
  RiceColors._();

  // Primary Colors
  static const Color riceBlue = Color(0xFF00205B);
  static const Color riceGray = Color(0xFF7C7E7F);

  // Secondary & Accent Colors
  static const Color darkBlue = Color(0xFF00143D);
  static const Color lightBlue = Color(0xFF4B729F);
  static const Color laurelGold = Color(0xFFC19B4C);

  // Neutral Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);

  // UI Surfaces & Slate Shades
  static const Color surfaceBackground = Color(0xFFF8FAFC);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color successGreen = Color(0xFF16A34A);

  /// Preset colors for QR code foreground selection
  static const List<RiceColorPreset> fgPresets = [
    RiceColorPreset('Rice Blue', riceBlue, '#00205B'),
    RiceColorPreset('Rice Gray', riceGray, '#7C7E7F'),
    RiceColorPreset('Dark Blue', darkBlue, '#00143D'),
    RiceColorPreset('Light Blue', lightBlue, '#4B729F'),
    RiceColorPreset('Laurel Gold', laurelGold, '#C19B4C'),
    RiceColorPreset('Black', black, '#000000'),
  ];

  /// Preset colors for QR code background selection
  static const List<RiceColorPreset> bgPresets = [
    RiceColorPreset('White', white, '#FFFFFF'),
    RiceColorPreset('Transparent', transparent, '#00000000'),
    RiceColorPreset('Rice Blue', riceBlue, '#00205B'),
    RiceColorPreset('Rice Gray', riceGray, '#7C7E7F'),
    RiceColorPreset('Light Blue', lightBlue, '#4B729F'),
    RiceColorPreset('Dark Blue', darkBlue, '#00143D'),
    RiceColorPreset('Black', black, '#000000'),
  ];
}

class RiceColorPreset {
  final String name;
  final Color color;
  final String hex;

  const RiceColorPreset(this.name, this.color, this.hex);
}
