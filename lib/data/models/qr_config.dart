import 'package:flutter/material.dart';
import '../../core/constants/rice_logos.dart';

enum QrStyle {
  square('Square', 'Classic sharp modules'),
  rounded('Rounded', 'Smooth rounded modules'),
  dots('Dots', 'Circular dot modules');

  final String label;
  final String description;
  const QrStyle(this.label, this.description);

  static QrStyle fromString(String? val) {
    if (val == null) return QrStyle.square;
    return QrStyle.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => QrStyle.square,
    );
  }
}

class QrConfig {
  final String fgColorHex;
  final String bgColorHex;
  final QrStyle style;
  final RiceLogoType logoType;

  const QrConfig({
    this.fgColorHex = '#00205B',
    this.bgColorHex = '#FFFFFF',
    this.style = QrStyle.square,
    this.logoType = RiceLogoType.shield,
  });

  Color get fgColor => _parseHexColor(fgColorHex, const Color(0xFF00205B));
  Color get bgColor => _parseHexColor(bgColorHex, const Color(0xFFFFFFFF));
  bool get isBgTransparent => bgColorHex.toLowerCase() == '#00000000' || bgColor.a == 0;

  static Color _parseHexColor(String hex, Color fallback) {
    var cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }
    if (cleaned.length == 8) {
      final val = int.tryParse(cleaned, radix: 16);
      if (val != null) return Color(val);
    }
    return fallback;
  }

  QrConfig copyWith({
    String? fgColorHex,
    String? bgColorHex,
    QrStyle? style,
    RiceLogoType? logoType,
  }) {
    return QrConfig(
      fgColorHex: fgColorHex ?? this.fgColorHex,
      bgColorHex: bgColorHex ?? this.bgColorHex,
      style: style ?? this.style,
      logoType: logoType ?? this.logoType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fgColorHex': fgColorHex,
      'bgColorHex': bgColorHex,
      'style': style.name,
      'logoType': logoType.name,
    };
  }

  factory QrConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const QrConfig();
    return QrConfig(
      fgColorHex: map['fgColorHex'] as String? ?? '#00205B',
      bgColorHex: map['bgColorHex'] as String? ?? '#FFFFFF',
      style: QrStyle.fromString(map['style'] as String?),
      logoType: RiceLogoType.fromString(map['logoType'] as String?),
    );
  }
}
