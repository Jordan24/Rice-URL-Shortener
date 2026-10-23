import 'package:flutter/material.dart';
import 'branding_pack.dart';
import 'rice_colors.dart';

/// Color definitions and raw preset definitions for Rice Residential Colleges.
class BrandingColorData {
  BrandingColorData._();

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFE0E2E6);
  static const Color transparent = Color(0x00000000);

  // College-specific primary & secondary colors
  static const Color bakerRed = Color(0xFFC8102E);
  static const Color bakerSilver = Color(0xFFA2AAAD);
  static const Color willRiceRust = Color(0xFFC03720);
  static const Color willRiceGold = Color(0xFFFECC37);
  static const Color hanszenRoyalBlue = Color(0xFF0099DD);
  static const Color hanszenYellow = Color(0xFFFFF100);
  static const Color hanszenBlack = Color(0xFF241F20);
  static const Color wiessGoldenrod = Color(0xFFDAA520);
  static const Color wiessWarmGold = Color(0xFFFFC72C);
  static const Color wiessSable = Color(0xFF1A1A1A);
  static const Color jonesForestGreen = Color(0xFF006400);
  static const Color jonesRoyalPurple = Color(0xFF582C83);
  static const Color jonesSkyBlue = Color(0xFF89CFF0);
  static const Color jonesSunGold = Color(0xFFFFD700);
  static const Color brownMaroon = Color(0xFF800020);
  static const Color brownWarmGold = Color(0xFFFFD700);
  static const Color brownLaurelGreen = Color(0xFF2D5A27);
  static const Color lovettNavy = Color(0xFF00205B);
  static const Color lovettGold = Color(0xFFFFD700);
  static const Color lovettCrimson = Color(0xFF9B111E);
  static const Color sidCardinalRed = Color(0xFFC41230);
  static const Color sidRichGold = Color(0xFFFFD700);
  static const Color sidJetBlack = Color(0xFF000000);
  static const Color martelSkyBlue = Color(0xFF0072CE);
  static const Color martelMaroon = Color(0xFF800000);
  static const Color mcmurtryPurple = Color(0xFF4B2E83);
  static const Color mcmurtrySilver = Color(0xFFC0C0C0);
  static const Color duncanForestGreen = Color(0xFF00432C);
  static const Color duncanLaurelGold = Color(0xFFE9A139);
  static const Color duncanIvory = Color(0xFFFFFFF0);
  static const Color chaoPink = Color(0xFFFF8DA1);
  static const Color chaoIvory = Color(0xFFFFF8E7);
  static const Color chaoNavy = Color(0xFF00205B);

  static const RiceColorPreset presetBlack = RiceColorPreset('Black', black, '#000000');
  static const RiceColorPreset presetWhite = RiceColorPreset('White', white, '#FFFFFF');
  static const RiceColorPreset presetLightGray = RiceColorPreset('Light Gray', lightGray, '#E0E2E6');
  static const RiceColorPreset presetTransparent = RiceColorPreset('Transparent', transparent, '#00000000');

  /// Curated college foreground color mappings
  static const Map<BrandingPackType, List<RiceColorPreset>> collegeFgMap = {
    BrandingPackType.baker: [
      RiceColorPreset('Baker Red', bakerRed, '#C8102E'),
      RiceColorPreset('Baker Silver', bakerSilver, '#A2AAAD'),
      RiceColorPreset('Crimson', Color(0xFF800000), '#800000'),
    ],
    BrandingPackType.willRice: [
      RiceColorPreset('Will Rice Rust', willRiceRust, '#C03720'),
      RiceColorPreset('Phoenix Gold', willRiceGold, '#FECC37'),
    ],
    BrandingPackType.hanszen: [
      RiceColorPreset('Royal Blue', hanszenRoyalBlue, '#0099DD'),
      RiceColorPreset('Canary Yellow', hanszenYellow, '#FFF100'),
      RiceColorPreset('Hanszen Black', hanszenBlack, '#241F20'),
    ],
    BrandingPackType.wiess: [
      RiceColorPreset('Goldenrod', wiessGoldenrod, '#DAA520'),
      RiceColorPreset('Warm Gold', wiessWarmGold, '#FFC72C'),
      RiceColorPreset('Wiess Sable', wiessSable, '#1A1A1A'),
    ],
    BrandingPackType.jones: [
      RiceColorPreset('Forest Green', jonesForestGreen, '#006400'),
      RiceColorPreset('Royal Purple', jonesRoyalPurple, '#582C83'),
      RiceColorPreset('Sky Blue', jonesSkyBlue, '#89CFF0'),
      RiceColorPreset('Sun Gold', jonesSunGold, '#FFD700'),
    ],
    BrandingPackType.brown: [
      RiceColorPreset('Brown Maroon', brownMaroon, '#800020'),
      RiceColorPreset('Warm Gold', brownWarmGold, '#FFD700'),
      RiceColorPreset('Laurel Green', brownLaurelGreen, '#2D5A27'),
      RiceColorPreset('Rice Blue', RiceColors.riceBlue, '#00205B'),
    ],
    BrandingPackType.lovett: [
      RiceColorPreset('Lovett Navy', lovettNavy, '#00205B'),
      RiceColorPreset('Collegiate Gold', lovettGold, '#FFD700'),
      RiceColorPreset('Crimson', lovettCrimson, '#9B111E'),
    ],
    BrandingPackType.sidRichardson: [
      RiceColorPreset('Cardinal Red', sidCardinalRed, '#C41230'),
      RiceColorPreset('Rich Gold', sidRichGold, '#FFD700'),
      RiceColorPreset('Jet Black', sidJetBlack, '#000000'),
    ],
    BrandingPackType.martel: [
      RiceColorPreset('Greek Sky Blue', martelSkyBlue, '#0072CE'),
      RiceColorPreset('Martel Maroon', martelMaroon, '#800000'),
      RiceColorPreset('Rice Navy', RiceColors.riceBlue, '#00205B'),
    ],
    BrandingPackType.mcmurtry: [
      RiceColorPreset('Royal McPurple', mcmurtryPurple, '#4B2E83'),
      RiceColorPreset('Scottish Silver', mcmurtrySilver, '#C0C0C0'),
    ],
    BrandingPackType.duncan: [
      RiceColorPreset('Duncan Forest Green', duncanForestGreen, '#00432C'),
      RiceColorPreset('Laurel Gold', duncanLaurelGold, '#E9A139'),
    ],
    BrandingPackType.chao: [
      RiceColorPreset('Chao Pink', chaoPink, '#FF8DA1'),
      RiceColorPreset('Chao Navy', chaoNavy, '#00205B'),
      RiceColorPreset('Azalea Rose', Color(0xFFE86F88), '#E86F88'),
    ],
  };
}
