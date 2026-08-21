
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

enum RiceLogoType {
  shield('Rice Shield / Crest', 'Academic Mark'),
  owl('Rice Owl', 'Spirit & Athletics'),
  oldEnglishR('Old English R', 'Heritage Mark'),
  none('None', 'Standard QR Code');

  final String label;
  final String description;
  const RiceLogoType(this.label, this.description);

  static RiceLogoType fromString(String? val) {
    if (val == null) return RiceLogoType.shield;
    return RiceLogoType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => RiceLogoType.shield,
    );
  }
}

class RiceLogos {
  RiceLogos._();

  static const String shieldPath = 'assets/logos/rice_shield.png';
  static const String owlPath = 'assets/logos/rice_owl.png';
  static const String rPath = 'assets/logos/rice_r.png';

  /// Returns the asset path for a given Rice logo type
  static String? getAssetPath(RiceLogoType type) {
    switch (type) {
      case RiceLogoType.shield:
        return shieldPath;
      case RiceLogoType.owl:
        return owlPath;
      case RiceLogoType.oldEnglishR:
        return rPath;
      case RiceLogoType.none:
        return null;
    }
  }

  static final Map<RiceLogoType, ui.Image> _uiImageCache = {};
  static final Map<RiceLogoType, String> _base64Cache = {};

  /// Loads and caches the ui.Image for Flutter Canvas rasterization
  static Future<ui.Image?> getUiImage(RiceLogoType type) async {
    if (type == RiceLogoType.none) return null;
    if (_uiImageCache.containsKey(type)) return _uiImageCache[type];

    final path = getAssetPath(type);
    if (path == null) return null;

    try {
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _uiImageCache[type] = frame.image;
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  /// Loads and caches base64 string for SVG `<image>` tag embedding
  static Future<String?> getBase64Png(RiceLogoType type) async {
    if (type == RiceLogoType.none) return null;
    if (_base64Cache.containsKey(type)) return _base64Cache[type];

    final path = getAssetPath(type);
    if (path == null) return null;

    try {
      final data = await rootBundle.load(path);
      final base64String = base64Encode(data.buffer.asUint8List());
      _base64Cache[type] = base64String;
      return base64String;
    } catch (_) {
      return null;
    }
  }
}
