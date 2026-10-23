import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rice_url_shortener/core/constants/rice_colors.dart';
import 'package:rice_url_shortener/core/utils/qr_contrast_helper.dart';

void main() {
  group('QrContrastHelper Luminance & Ratio Tests', () {
    test('calculateRelativeLuminance matches standard values', () {
      expect(QrContrastHelper.calculateRelativeLuminance(Colors.black), 0.0);
      expect(QrContrastHelper.calculateRelativeLuminance(Colors.white), 1.0);

      // Rice Blue is dark
      final riceBlueLum = QrContrastHelper.calculateRelativeLuminance(RiceColors.riceBlue);
      expect(riceBlueLum, closeTo(0.018, 0.005));

      // Light Gray is light
      final lightGrayLum = QrContrastHelper.calculateRelativeLuminance(RiceColors.lightGray);
      expect(lightGrayLum, closeTo(0.760, 0.010));
    });

    test('calculateContrastRatio calculates standard ratios', () {
      // Pure black on pure white should be 21:1
      expect(
        QrContrastHelper.calculateContrastRatio(Colors.black, Colors.white),
        closeTo(21.0, 0.01),
      );

      // Same color should be 1.0:1
      expect(
        QrContrastHelper.calculateContrastRatio(Colors.blue, Colors.blue),
        closeTo(1.0, 0.01),
      );

      // Rice Blue on White should be > 15:1
      expect(
        QrContrastHelper.calculateContrastRatio(RiceColors.riceBlue, RiceColors.white),
        greaterThan(15.0),
      );
    });

    test('parseHexColor handles 6-digit and 8-digit hex', () {
      final c1 = QrContrastHelper.parseHexColor('#00205B');
      expect(c1, const Color(0xFF00205B));

      final c2 = QrContrastHelper.parseHexColor('#8000205B');
      expect(c2.a, closeTo(0.5, 0.01));

      final c3 = QrContrastHelper.parseHexColor('invalid', fallback: Colors.red);
      expect(c3, Colors.red);
    });
  });

  group('QrContrastHelper validateContrast Standards Tests', () {
    test('Compliant: Rice Blue on White passes QR standards', () {
      final result = QrContrastHelper.validateContrast(
        fgHex: '#00205B',
        bgHex: '#FFFFFF',
      );
      expect(result.status, QrContrastStatus.compliant);
      expect(result.severity, QrContrastSeverity.none);
      expect(result.isStandardCompliant, isTrue);
      expect(result.hasWarning, isFalse);
      expect(result.contrastRatio, greaterThan(15.0));
    });

    test('Compliant: Black on White has maximum contrast', () {
      final result = QrContrastHelper.validateContrast(
        fgHex: '#000000',
        bgHex: '#FFFFFF',
      );
      expect(result.status, QrContrastStatus.compliant);
      expect(result.hasWarning, isFalse);
      expect(result.contrastRatio, closeTo(21.0, 0.1));
    });

    test('Inverted: White foreground on Rice Blue background fails polarity standard', () {
      final result = QrContrastHelper.validateContrast(
        fgHex: '#FFFFFF',
        bgHex: '#00205B',
      );
      expect(result.status, QrContrastStatus.inverted);
      expect(result.severity, QrContrastSeverity.critical);
      expect(result.isStandardCompliant, isFalse);
      expect(result.hasWarning, isTrue);
      expect(result.title, contains('Inverted'));
      expect(result.message, contains('ISO/IEC 18004'));
    });

    test('Critical: Medium Blue on Light Blue Gray has ratio < 3.0:1', () {
      // Medium Blue (#4D9AD4) on Light Blue Gray (#ADC7DC) -> ~1.74:1
      final result = QrContrastHelper.validateContrast(
        fgHex: '#4D9AD4',
        bgHex: '#ADC7DC',
      );
      expect(result.status, QrContrastStatus.criticalContrast);
      expect(result.severity, QrContrastSeverity.critical);
      expect(result.isStandardCompliant, isFalse);
      expect(result.hasWarning, isTrue);
      expect(result.contrastRatio, lessThan(3.0));
      expect(result.title, contains('Critically Low Contrast'));
    });

    test('Critical: Same color FG and BG has ratio 1.0:1', () {
      final result = QrContrastHelper.validateContrast(
        fgHex: '#4D9AD4',
        bgHex: '#4D9AD4',
      );
      expect(result.status, QrContrastStatus.criticalContrast);
      expect(result.contrastRatio, closeTo(1.0, 0.01));
    });

    test('Warning: Medium Blue on White has 3.0:1 <= ratio < 4.0:1', () {
      // Medium Blue (#4D9AD4) on White (#FFFFFF) -> ~3.05:1
      final result = QrContrastHelper.validateContrast(
        fgHex: '#4D9AD4',
        bgHex: '#FFFFFF',
      );
      expect(result.status, QrContrastStatus.lowContrast);
      expect(result.severity, QrContrastSeverity.warning);
      expect(result.isStandardCompliant, isFalse);
      expect(result.hasWarning, isTrue);
      expect(result.contrastRatio, greaterThanOrEqualTo(3.0));
      expect(result.contrastRatio, lessThan(4.0));
      expect(result.title, contains('Low Contrast Warning'));
    });

    test('Transparent BG with light foreground fails standard', () {
      // Bright Blue (#9FDDF9) on Transparent
      final result = QrContrastHelper.validateContrast(
        fgHex: '#9FDDF9',
        bgHex: '#00000000',
      );
      expect(result.status, QrContrastStatus.transparentLightFg);
      expect(result.severity, QrContrastSeverity.critical);
      expect(result.hasWarning, isTrue);
    });

    test('Transparent BG with dark foreground passes standard', () {
      // Rice Blue (#00205B) on Transparent
      final result = QrContrastHelper.validateContrast(
        fgHex: '#00205B',
        bgHex: '#00000000',
      );
      expect(result.status, QrContrastStatus.compliant);
      expect(result.hasWarning, isFalse);
    });
  });
}
