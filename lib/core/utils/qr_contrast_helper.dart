import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/rice_colors.dart';

/// Compliance status of QR code color contrast against ISO/IEC 18004 standards.
enum QrContrastStatus { compliant, lowContrast, criticalContrast, inverted, transparentLightFg }

/// Severity level for contrast feedback.
enum QrContrastSeverity { none, warning, critical }

/// Evaluation result describing QR code color contrast readability.
class QrContrastResult {
  final QrContrastStatus status;
  final QrContrastSeverity severity;
  final double contrastRatio;
  final double fgLuminance;
  final double bgLuminance;
  final bool isTransparentBg;
  final String title;
  final String message;
  final String recommendation;

  const QrContrastResult({
    required this.status,
    required this.severity,
    required this.contrastRatio,
    required this.fgLuminance,
    required this.bgLuminance,
    required this.isTransparentBg,
    required this.title,
    required this.message,
    required this.recommendation,
  });

  bool get isStandardCompliant => status == QrContrastStatus.compliant;
  bool get hasWarning => !isStandardCompliant;
  String get formattedRatio => '${contrastRatio.toStringAsFixed(1)}:1';
}

/// Helper utility for calculating luminance and validating QR code color contrast
/// against ISO/IEC 18004 and ISO/IEC 15415 standards.
class QrContrastHelper {
  QrContrastHelper._();

  static const double standardMinContrastRatio = 4.0;
  static const double criticalMinContrastRatio = 3.0;
  static const double maxTransparentFgLuminance = 0.40;

  static Color parseHexColor(String hex, {Color fallback = RiceColors.riceBlue}) {
    var cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    if (cleaned.length == 8) {
      final val = int.tryParse(cleaned, radix: 16);
      if (val != null) return Color(val);
    }
    return fallback;
  }

  static double calculateRelativeLuminance(Color color) => color.computeLuminance();

  static double calculateContrastRatio(Color color1, Color color2) {
    final l1 = color1.computeLuminance();
    final l2 = color2.computeLuminance();
    return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
  }

  static bool isTransparent(String hex, Color color) {
    final clean = hex.replaceAll('#', '').trim().toLowerCase();
    return clean == '00000000' || clean == '0' || clean == 'none' || color.a == 0;
  }

  static QrContrastResult validateContrast({required String fgHex, required String bgHex}) {
    final fgColor = parseHexColor(fgHex, fallback: RiceColors.riceBlue);
    final bgColor = parseHexColor(bgHex, fallback: RiceColors.white);
    final isBgTrans = isTransparent(bgHex, bgColor);

    final fgLum = calculateRelativeLuminance(fgColor);
    final bgLum = calculateRelativeLuminance(bgColor);
    final ratio = calculateContrastRatio(fgColor, bgColor);

    if (isBgTrans) {
      if (fgLum > maxTransparentFgLuminance) {
        return QrContrastResult(
          status: QrContrastStatus.transparentLightFg,
          severity: QrContrastSeverity.critical,
          contrastRatio: calculateContrastRatio(fgColor, RiceColors.white),
          fgLuminance: fgLum,
          bgLuminance: 1.0,
          isTransparentBg: true,
          title: 'Light Foreground on Transparent',
          message: 'A light foreground color with a transparent background lacks sufficient contrast when displayed on light surfaces.',
          recommendation: 'Select a darker foreground color (like Rice Blue) or an opaque background.',
        );
      }
      return QrContrastResult(
        status: QrContrastStatus.compliant,
        severity: QrContrastSeverity.none,
        contrastRatio: calculateContrastRatio(fgColor, RiceColors.white),
        fgLuminance: fgLum,
        bgLuminance: 1.0,
        isTransparentBg: true,
        title: 'Meets Standards',
        message: 'Ensure this transparent QR code is placed on a light, high-contrast surface.',
        recommendation: '',
      );
    }

    // 1. Inverted polarity (light modules on dark background)
    if (fgLum > bgLum) {
      return QrContrastResult(
        status: QrContrastStatus.inverted,
        severity: QrContrastSeverity.critical,
        contrastRatio: ratio,
        fgLuminance: fgLum,
        bgLuminance: bgLum,
        isTransparentBg: false,
        title: 'Inverted Contrast (Light on Dark)',
        message: 'Foreground modules are lighter than background. ISO/IEC 18004 standards specify dark modules on light background. Many mobile cameras cannot decode inverted QR codes.',
        recommendation: 'Swap the colors or choose a dark foreground and light background.',
      );
    }

    // 2. Critically low contrast (< 3.0:1)
    if (ratio < criticalMinContrastRatio) {
      return QrContrastResult(
        status: QrContrastStatus.criticalContrast,
        severity: QrContrastSeverity.critical,
        contrastRatio: ratio,
        fgLuminance: fgLum,
        bgLuminance: bgLum,
        isTransparentBg: false,
        title: 'Critically Low Contrast',
        message: 'Contrast ratio is ${ratio.toStringAsFixed(1)}:1, well below the required 4.0:1 standard. Modules are nearly indistinguishable and scanners will fail.',
        recommendation: 'Select a much darker foreground (like Rice Blue) or lighter background.',
      );
    }

    // 3. Substandard low contrast (3.0:1 <= ratio < 4.0:1)
    if (ratio < standardMinContrastRatio) {
      return QrContrastResult(
        status: QrContrastStatus.lowContrast,
        severity: QrContrastSeverity.warning,
        contrastRatio: ratio,
        fgLuminance: fgLum,
        bgLuminance: bgLum,
        isTransparentBg: false,
        title: 'Low Contrast Warning',
        message: 'Contrast ratio of ${ratio.toStringAsFixed(1)}:1 is below the recommended 4.0:1 standard. Some cameras or dim lighting conditions may fail to scan.',
        recommendation: 'Choose a darker foreground or lighter background for reliable scanning.',
      );
    }

    // 4. Meets standards
    return QrContrastResult(
      status: QrContrastStatus.compliant,
      severity: QrContrastSeverity.none,
      contrastRatio: ratio,
      fgLuminance: fgLum,
      bgLuminance: bgLum,
      isTransparentBg: false,
      title: 'Meets Standards',
      message: 'High contrast (${ratio.toStringAsFixed(1)}:1). Compliant with ISO/IEC 18004 QR standards.',
      recommendation: '',
    );
  }
}
