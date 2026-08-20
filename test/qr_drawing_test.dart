import 'package:flutter_test/flutter_test.dart';
import 'package:qr/qr.dart';
import 'package:rice_url_shortener/core/utils/qr_drawing_helper.dart';
import 'package:rice_url_shortener/data/models/qr_config.dart';
import 'package:rice_url_shortener/data/services/qr_export_service.dart';

void main() {
  group('QrDrawingHelper Tests', () {
    test('Finder pattern coordinates detection', () {
      const moduleCount = 29;

      // Top-Left Finder (0..6, 0..6)
      expect(QrDrawingHelper.isFinderPattern(0, 0, moduleCount), isTrue);
      expect(QrDrawingHelper.isFinderPattern(6, 6, moduleCount), isTrue);
      expect(QrDrawingHelper.isFinderPattern(7, 0, moduleCount), isFalse);

      // Top-Right Finder (22..28, 0..6)
      expect(QrDrawingHelper.isFinderPattern(22, 0, moduleCount), isTrue);
      expect(QrDrawingHelper.isFinderPattern(28, 6, moduleCount), isTrue);
      expect(QrDrawingHelper.isFinderPattern(21, 0, moduleCount), isFalse);

      // Bottom-Left Finder (0..6, 22..28)
      expect(QrDrawingHelper.isFinderPattern(0, 22, moduleCount), isTrue);
      expect(QrDrawingHelper.isFinderPattern(6, 28, moduleCount), isTrue);
      expect(QrDrawingHelper.isFinderPattern(0, 21, moduleCount), isFalse);

      // Center data area
      expect(QrDrawingHelper.isFinderPattern(14, 14, moduleCount), isFalse);
    });

    test('Alignment pattern centers detection for QR Version 3 (29x29)', () {
      final centers = QrDrawingHelper.getAlignmentCenters(29);
      expect(centers.isNotEmpty, isTrue);
      expect(centers.any((c) => c.x == 22 && c.y == 22), isTrue);
    });
  });

  group('QrExportService Generation Tests', () {
    test('generateSvg includes quiet zone in viewBox and translation group', () {
      const config = QrConfig(style: QrStyle.square);
      const url = 'https://link.thejambers.com/r/test1';
      const quietZone = 4;
      final qrCode = QrCode.fromData(data: url, errorCorrectLevel: QrErrorCorrectLevel.H);
      final totalModules = QrImage(qrCode).moduleCount + (quietZone * 2);

      final svg = QrExportService.generateSvg(url, config, quietZone: quietZone);
      expect(svg, contains('viewBox="0 0 $totalModules $totalModules"'));
      expect(svg, contains('<rect width="$totalModules" height="$totalModules" fill="#FFFFFF"/>'));
      expect(svg, contains('<g transform="translate(4, 4)">'));
      expect(svg, contains('</g>'));
    });

    test('generateSvg produces valid SVG for Square style', () {
      const config = QrConfig(style: QrStyle.square);
      final svg = QrExportService.generateSvg('https://link.thejambers.com/r/test1', config);
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
      expect(svg, contains('<rect'));
    });

    test('generateSvg produces valid SVG for Rounded style', () {
      const config = QrConfig(style: QrStyle.rounded);
      final svg = QrExportService.generateSvg('https://link.thejambers.com/r/test2', config);
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
      expect(svg, contains('path'));
    });

    test('generateSvg produces valid SVG for Dots style', () {
      const config = QrConfig(style: QrStyle.dots);
      final svg = QrExportService.generateSvg('https://link.thejambers.com/r/test3', config);
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
      expect(svg, contains('<circle'));
    });
  });
}
