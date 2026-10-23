import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:rice_url_shortener/core/constants/rice_logos.dart';
import 'package:rice_url_shortener/data/models/qr_config.dart';
import 'package:rice_url_shortener/data/services/qr_export_service.dart';

void main() {
  test('Verify Rice Owl and Old English R logo assets have transparent backgrounds', () {
    expect(RiceLogoType.values, containsAll([RiceLogoType.owl, RiceLogoType.oldEnglishR, RiceLogoType.none]));

    for (final path in [RiceLogos.owlPath, RiceLogos.rPath]) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Missing $path');
      final decoded = img.decodePng(file.readAsBytesSync())!;
      expect(decoded.width, equals(512));
      expect(decoded.height, equals(512));
      // Corner pixel must be fully transparent
      expect(decoded.getPixel(0, 0).a, equals(0));
    }

    // Verify Owl interior pixel is also transparent so background shows through
    final owlDecoded = img.decodePng(File(RiceLogos.owlPath).readAsBytesSync())!;
    expect(owlDecoded.getPixel(256, 300).a, equals(0));
  });

  test('Verify SVG export colors center logo with foreground color and omits white background cutout', () {
    const config = QrConfig(
      fgColorHex: '#4D9AD4',
      bgColorHex: '#ADC7DC',
      style: QrStyle.rounded,
      logoType: RiceLogoType.owl,
    );

    final svg = QrExportService.generateSvg('https://go.thejambers.com/owl-test', config);
    expect(svg, contains('<path fill="#4D9AD4" fill-rule="evenodd" d="M '));
    expect(svg, isNot(contains('fill="white"')));
  });
}
