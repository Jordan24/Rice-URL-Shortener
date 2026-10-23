import 'package:flutter/material.dart';
import 'branding_color_data.dart';
import 'branding_pack.dart';
import 'rice_colors.dart';

/// Preset color palettes tailored for Rice University and the 12 Residential Colleges.
class BrandingColors {
  BrandingColors._();

  static const Color black = BrandingColorData.black;
  static const Color white = BrandingColorData.white;
  static const Color lightGray = BrandingColorData.lightGray;
  static const Color transparent = BrandingColorData.transparent;

  static const RiceColorPreset presetBlack = BrandingColorData.presetBlack;
  static const RiceColorPreset presetWhite = BrandingColorData.presetWhite;
  static const RiceColorPreset presetLightGray = BrandingColorData.presetLightGray;
  static const RiceColorPreset presetTransparent = BrandingColorData.presetTransparent;

  /// Returns the default foreground color hex for a given branding pack
  static String getDefaultFgColorHex(BrandingPackType pack) {
    switch (pack) {
      case BrandingPackType.university:
        return '#00205B';
      case BrandingPackType.baker:
        return '#C8102E';
      case BrandingPackType.willRice:
        return '#C03720';
      case BrandingPackType.hanszen:
        return '#0099DD';
      case BrandingPackType.wiess:
        return '#DAA520';
      case BrandingPackType.jones:
        return '#006400';
      case BrandingPackType.brown:
        return '#800020';
      case BrandingPackType.lovett:
        return '#00205B';
      case BrandingPackType.sidRichardson:
        return '#C41230';
      case BrandingPackType.martel:
        return '#0072CE';
      case BrandingPackType.mcmurtry:
        return '#4B2E83';
      case BrandingPackType.duncan:
        return '#00432C';
      case BrandingPackType.chao:
        return '#FF8DA1';
    }
  }

  /// Returns the default background color hex for a given branding pack
  static String getDefaultBgColorHex(BrandingPackType pack) => '#FFFFFF';

  /// Returns the curated list of foreground presets for a given branding pack
  static List<RiceColorPreset> getFgPresets(BrandingPackType pack) {
    if (pack == BrandingPackType.university) {
      return RiceColors.fgPresets;
    }

    final collegeColors = List<RiceColorPreset>.from(BrandingColorData.collegeFgMap[pack] ?? const []);
    if (!collegeColors.any((p) => p.hex.toLowerCase() == '#000000')) {
      collegeColors.add(presetBlack);
    }
    return collegeColors;
  }

  /// Returns the curated list of background presets for a given branding pack
  static List<RiceColorPreset> getBgPresets(BrandingPackType pack) {
    if (pack == BrandingPackType.university) {
      return RiceColors.bgPresets;
    }

    final bgList = <RiceColorPreset>[presetWhite];

    switch (pack) {
      case BrandingPackType.baker:
        bgList.add(const RiceColorPreset('Silver Tint', Color(0xFFF2F4F5), '#F2F4F5'));
        break;
      case BrandingPackType.willRice:
        bgList.add(const RiceColorPreset('Gold Tint', Color(0xFFFFF9E6), '#FFF9E6'));
        break;
      case BrandingPackType.hanszen:
        bgList.add(const RiceColorPreset('Canary Yellow', BrandingColorData.hanszenYellow, '#FFF100'));
        bgList.add(const RiceColorPreset('Yellow Tint', Color(0xFFFFFDE0), '#FFFDE0'));
        break;
      case BrandingPackType.wiess:
        bgList.add(const RiceColorPreset('Goldenrod Tint', Color(0xFFFFF8E7), '#FFF8E7'));
        bgList.add(const RiceColorPreset('Wiess Black', BrandingColorData.wiessSable, '#1A1A1A'));
        break;
      case BrandingPackType.jones:
        bgList.add(const RiceColorPreset('Sky Blue Tint', Color(0xFFEBF7FD), '#EBF7FD'));
        bgList.add(const RiceColorPreset('Lavender Tint', Color(0xFFF4EFF9), '#F4EFF9'));
        break;
      case BrandingPackType.brown:
      case BrandingPackType.lovett:
        bgList.add(const RiceColorPreset('Gold Tint', Color(0xFFFFF9E6), '#FFF9E6'));
        if (pack == BrandingPackType.lovett) {
          bgList.add(const RiceColorPreset('Light Blue Gray', RiceColors.lightBlueGray, '#ADC7DC'));
        }
        break;
      case BrandingPackType.sidRichardson:
        bgList.add(const RiceColorPreset('Cardinal Tint', Color(0xFFFDF0F2), '#FDF0F2'));
        break;
      case BrandingPackType.martel:
        bgList.add(const RiceColorPreset('Azure Tint', Color(0xFFE6F2FA), '#E6F2FA'));
        break;
      case BrandingPackType.mcmurtry:
        bgList.add(const RiceColorPreset('Purple Tint', Color(0xFFF4EFF9), '#F4EFF9'));
        break;
      case BrandingPackType.duncan:
        bgList.add(const RiceColorPreset('Ivory', BrandingColorData.duncanIvory, '#FFFFF0'));
        bgList.add(const RiceColorPreset('Green Tint', Color(0xFFEAF4EE), '#EAF4EE'));
        break;
      case BrandingPackType.chao:
        bgList.add(const RiceColorPreset('Chao Ivory', BrandingColorData.chaoIvory, '#FFF8E7'));
        bgList.add(const RiceColorPreset('Pink Tint', Color(0xFFFFF0F3), '#FFF0F3'));
        break;
      case BrandingPackType.university:
        break;
    }

    bgList.add(presetLightGray);
    bgList.add(presetTransparent);
    return bgList;
  }
}
