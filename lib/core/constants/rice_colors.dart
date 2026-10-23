import 'package:flutter/material.dart';

/// Official Rice University Brand Colors (https://brand.rice.edu/colors)
class RiceColors {
  RiceColors._();

  // Primary Core Colors (brand.rice.edu/colors)
  static const Color riceBlue = Color(0xFF00205B);
  static const Color riceGray = Color(0xFF7C7E7F);

  // Extended Blue & Gray Palette (brand.rice.edu/colors)
  static const Color lightGray = Color(0xFFE0E2E6);
  static const Color darkGray = Color(0xFF44474F);
  static const Color lightBlueGray = Color(0xFFADC7DC);
  static const Color darkBlueGray = Color(0xFF303B61);
  static const Color brightBlue = Color(0xFF9FDDF9);
  static const Color mediumBlue = Color(0xFF4D9AD4);
  static const Color richBlue = Color(0xFF0A509E);

  // Extended Campus Accent Palette (brand.rice.edu/colors)
  static const Color grassGreen = Color(0xFF359245);
  static const Color treeGreen = Color(0xFF00432C);
  static const Color leafEmerald = Color(0xFF005B50);
  static const Color warmYellow = Color(0xFFE9A139);
  static const Color brickRed = Color(0xFFC04829);
  static const Color burgundy = Color(0xFF68132E);

  // Black, White & Transparent
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);

  // Semantic UI Mappings (strictly mapped to official brand.rice.edu/colors)
  static const Color darkBlue = darkBlueGray;
  static const Color lightBlue = lightBlueGray;
  static const Color laurelGold = warmYellow;
  static const Color offWhite = lightGray;
  static const Color accentLightBlue = brightBlue;
  static const Color surfaceBackground = lightGray;
  static const Color surfaceCard = white;
  static const Color borderLight = lightBlueGray;
  static const Color textPrimary = darkGray;
  static const Color textSecondary = riceGray;
  static const Color errorRed = brickRed;
  static const Color successGreen = grassGreen;

  /// Preset colors for QR code foreground selection (brand.rice.edu/colors)
  static const List<RiceColorPreset> fgPresets = [
    RiceColorPreset('Rice Blue', riceBlue, '#00205B'),
    RiceColorPreset('Rice Gray', riceGray, '#7C7E7F'),
    RiceColorPreset('Rich Blue', richBlue, '#0A509E'),
    RiceColorPreset('Medium Blue', mediumBlue, '#4D9AD4'),
    RiceColorPreset('Dark Blue Gray', darkBlueGray, '#303B61'),
    RiceColorPreset('Dark Gray', darkGray, '#44474F'),
    RiceColorPreset('Tree Green', treeGreen, '#00432C'),
    RiceColorPreset('Leaf Emerald', leafEmerald, '#005B50'),
    RiceColorPreset('Burgundy', burgundy, '#68132E'),
    RiceColorPreset('Brick Red', brickRed, '#C04829'),
    RiceColorPreset('Black', black, '#000000'),
  ];

  /// Preset colors for QR code background selection (light brand tones & transparent)
  static const List<RiceColorPreset> bgPresets = [
    RiceColorPreset('White', white, '#FFFFFF'),
    RiceColorPreset('Light Gray', lightGray, '#E0E2E6'),
    RiceColorPreset('Light Blue Gray', lightBlueGray, '#ADC7DC'),
    RiceColorPreset('Bright Blue', brightBlue, '#9FDDF9'),
    RiceColorPreset('Medium Blue', mediumBlue, '#4D9AD4'),
    RiceColorPreset('Warm Yellow', warmYellow, '#E9A139'),
    RiceColorPreset('Transparent', transparent, '#00000000'),
  ];
}

class RiceColorPreset {
  final String name;
  final Color color;
  final String hex;

  const RiceColorPreset(this.name, this.color, this.hex);
}
