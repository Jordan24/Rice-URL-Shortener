import 'dart:convert';
import 'dart:io' show File;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'branding_pack.dart';
import 'college_logo_paths_north.dart';
import 'college_logo_paths_south.dart';
import 'rice_logo_paths.dart';

enum RiceLogoType {
  // University Marks
  owl('Rice Owl', 'Academic & Spirit Mark', BrandingPackType.university),
  oldEnglishR('Old English R', 'Heritage Mark', BrandingPackType.university),

  // Residential College Marks
  baker('Baker Shield', 'Historic College Arms & Owls', BrandingPackType.baker),
  willRice('Will Rice Phoenix', 'Rising Phoenix of Will Rice', BrandingPackType.willRice),
  hanszen('Hanszen Crest', 'Crowned Lion & Eagle Shield', BrandingPackType.hanszen),
  wiess('Wiess Shield', 'Wiess Griffin & Athenian Owl', BrandingPackType.wiess),
  jones('Jones Shield', 'Sun in Splendour & Acorns', BrandingPackType.jones),
  brown('Brown Crest', 'Brown Tower & Rising Sun', BrandingPackType.brown),
  lovett('Lovett Shield', 'Lovett Chevron & Wolves', BrandingPackType.lovett),
  sidRichardson('Sid Richardson Crest', 'Castle Tower & Lightning Bolt', BrandingPackType.sidRichardson),
  martel('Martel Shield', 'Athenian Owl & Greek Cross', BrandingPackType.martel),
  mcmurtry('McMurtry Crest', 'Scottish Lion Rampant & Thistles', BrandingPackType.mcmurtry),
  duncan('Duncan Shield', 'Duncan Oak & Rising Sun', BrandingPackType.duncan),
  chao('Chao Crest', 'Twin Imperial Dragons & Azaleas', BrandingPackType.chao),

  // Generic
  none('None', 'Standard QR Code', null);

  /// Legacy alias mapped to [RiceLogoType.owl] for backward compatibility
  static const RiceLogoType shield = RiceLogoType.owl;

  final String label;
  final String description;
  final BrandingPackType? pack;

  const RiceLogoType(this.label, this.description, [this.pack]);

  /// True if this logo is a Rice University mark (owl or Old English R)
  bool get isUniversityMark => pack == BrandingPackType.university;

  static RiceLogoType fromString(String? val) {
    if (val == null || val.toLowerCase() == 'shield') return RiceLogoType.owl;
    return RiceLogoType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => RiceLogoType.owl,
    );
  }
}

class RiceLogos {
  RiceLogos._();

  static const String owlPath = 'assets/logos/rice_owl.png';
  static const String rPath = 'assets/logos/rice_r.png';
  static const String shieldPath = owlPath;

  /// Returns the PNG asset path for a given logo type
  static String? getAssetPath(RiceLogoType type) => switch (type) {
    RiceLogoType.owl => owlPath,
    RiceLogoType.oldEnglishR => rPath,
    RiceLogoType.baker => 'assets/logos/college_baker.png',
    RiceLogoType.willRice => 'assets/logos/college_will_rice.png',
    RiceLogoType.hanszen => 'assets/logos/college_hanszen.png',
    RiceLogoType.wiess => 'assets/logos/college_wiess.png',
    RiceLogoType.jones => 'assets/logos/college_jones.png',
    RiceLogoType.brown => 'assets/logos/college_brown.png',
    RiceLogoType.lovett => 'assets/logos/college_lovett.png',
    RiceLogoType.sidRichardson => 'assets/logos/college_sid_richardson.png',
    RiceLogoType.martel => 'assets/logos/college_martel.png',
    RiceLogoType.mcmurtry => 'assets/logos/college_mcmurtry.png',
    RiceLogoType.duncan => 'assets/logos/college_duncan.png',
    RiceLogoType.chao => 'assets/logos/college_chao.png',
    RiceLogoType.none => null,
  };

  /// Returns the vector SVG `<path>` `d` attribute string (512x512 viewBox)
  static String? getSvgPathData(RiceLogoType type) => switch (type) {
    RiceLogoType.owl => RiceLogoPaths.owlPathData,
    RiceLogoType.oldEnglishR => RiceLogoPaths.rPathData,
    RiceLogoType.baker => CollegeLogoPathsSouth.bakerPathData,
    RiceLogoType.willRice => CollegeLogoPathsSouth.willRicePathData,
    RiceLogoType.hanszen => CollegeLogoPathsSouth.hanszenPathData,
    RiceLogoType.wiess => CollegeLogoPathsSouth.wiessPathData,
    RiceLogoType.jones => CollegeLogoPathsNorth.jonesPathData,
    RiceLogoType.brown => CollegeLogoPathsNorth.brownPathData,
    RiceLogoType.lovett => CollegeLogoPathsSouth.lovettPathData,
    RiceLogoType.sidRichardson => CollegeLogoPathsSouth.sidRichardsonPathData,
    RiceLogoType.martel => CollegeLogoPathsNorth.martelPathData,
    RiceLogoType.mcmurtry => CollegeLogoPathsNorth.mcmurtryPathData,
    RiceLogoType.duncan => CollegeLogoPathsNorth.duncanPathData,
    RiceLogoType.chao => CollegeLogoPathsNorth.chaoPathData,
    RiceLogoType.none => null,
  };

  /// Returns the available logo options for a given branding pack
  static List<RiceLogoType> getLogosForPack(BrandingPackType pack) {
    if (pack == BrandingPackType.university) {
      return const [RiceLogoType.owl, RiceLogoType.oldEnglishR, RiceLogoType.none];
    }
    final collegeLogo = RiceLogoType.values.firstWhere(
      (l) => l.pack == pack,
      orElse: () => RiceLogoType.none,
    );
    return [collegeLogo, RiceLogoType.none];
  }

  /// Returns the default center logo for a given branding pack
  static RiceLogoType getDefaultLogoForPack(BrandingPackType pack) {
    if (pack == BrandingPackType.university) {
      return RiceLogoType.owl;
    }
    return RiceLogoType.values.firstWhere(
      (l) => l.pack == pack,
      orElse: () => RiceLogoType.none,
    );
  }

  /// Returns the logo type representing this pack in selectors and UI lists.
  /// For residential colleges, this is the college crest/shield logo.
  /// For Rice University, this is the Rice R mark.
  static RiceLogoType getSelectorLogoForPack(BrandingPackType pack) {
    if (pack == BrandingPackType.university) {
      return RiceLogoType.oldEnglishR;
    }
    return getDefaultLogoForPack(pack);
  }

  /// Returns the asset path representing this pack in selectors and UI lists
  static String? getSelectorAssetPath(BrandingPackType pack) {
    return getAssetPath(getSelectorLogoForPack(pack));
  }

  static final Map<RiceLogoType, ui.Image> _uiImageCache = {};
  static final Map<RiceLogoType, String> _base64Cache = {};

  static Future<Uint8List?> _loadAssetBytes(String path) async {
    try {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } catch (_) {
      try {
        final file = File(path);
        if (file.existsSync()) return file.readAsBytesSync();
      } catch (_) {}
      return null;
    }
  }

  /// Loads and caches the ui.Image for Flutter Canvas rasterization
  static Future<ui.Image?> getUiImage(RiceLogoType type) async {
    if (type == RiceLogoType.none) return null;
    if (_uiImageCache.containsKey(type)) return _uiImageCache[type];

    final path = getAssetPath(type);
    if (path == null) return null;

    try {
      final bytes = await _loadAssetBytes(path);
      if (bytes == null) return null;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _uiImageCache[type] = frame.image;
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  /// Loads and caches base64 string for PNG embedding
  static Future<String?> getBase64Png(RiceLogoType type) async {
    if (type == RiceLogoType.none) return null;
    if (_base64Cache.containsKey(type)) return _base64Cache[type];

    final path = getAssetPath(type);
    if (path == null) return null;

    try {
      final bytes = await _loadAssetBytes(path);
      if (bytes == null) return null;
      final base64String = base64Encode(bytes);
      _base64Cache[type] = base64String;
      return base64String;
    } catch (_) {
      return null;
    }
  }
}
