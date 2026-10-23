import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:rice_url_shortener/core/constants/branding_pack.dart';
import 'package:rice_url_shortener/core/constants/rice_logos.dart';
import 'package:rice_url_shortener/data/models/qr_config.dart';
import 'package:rice_url_shortener/data/services/qr_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('All 12 Residential College crest PNGs exist, are 512x512, and transparent', () async {
    const collegePacks = [
      BrandingPackType.baker,
      BrandingPackType.willRice,
      BrandingPackType.hanszen,
      BrandingPackType.wiess,
      BrandingPackType.jones,
      BrandingPackType.brown,
      BrandingPackType.lovett,
      BrandingPackType.sidRichardson,
      BrandingPackType.martel,
      BrandingPackType.mcmurtry,
      BrandingPackType.duncan,
      BrandingPackType.chao,
    ];

    for (final pack in collegePacks) {
      final logoType = RiceLogos.getDefaultLogoForPack(pack);
      final assetPath = RiceLogos.getAssetPath(logoType);
      expect(assetPath, isNotNull, reason: 'Missing asset path for ${pack.label}');

      final file = File(assetPath!);
      expect(file.existsSync(), isTrue, reason: 'File does not exist: $assetPath');

      final bytes = file.readAsBytesSync();
      expect(bytes.length, greaterThan(1000), reason: 'File too small: $assetPath');

      final decoded = img.decodePng(bytes);
      expect(decoded, isNotNull, reason: 'Failed to decode PNG: $assetPath');
      expect(decoded!.width, equals(512));
      expect(decoded.height, equals(512));
      expect(decoded.getPixel(0, 0).a, equals(0), reason: 'Top-left must be transparent for $assetPath');
      expect(decoded.getPixel(511, 0).a, equals(0), reason: 'Top-right must be transparent for $assetPath');
      expect(decoded.getPixel(0, 511).a, equals(0), reason: 'Bottom-left must be transparent for $assetPath');
      expect(decoded.getPixel(511, 511).a, equals(0), reason: 'Bottom-right must be transparent for $assetPath');
      expect(decoded.getPixel(256, 5).a, equals(0), reason: 'Top-mid must be transparent for $assetPath');
      expect(decoded.getPixel(5, 256).a, equals(0), reason: 'Left-mid must be transparent for $assetPath');

      // Verify RiceLogos base64 and uiImage helpers
      final base64String = await RiceLogos.getBase64Png(logoType);
      expect(base64String, isNotNull);
      expect(base64String!.length, greaterThan(100));

      final uiImage = await RiceLogos.getUiImage(logoType);
      expect(uiImage, isNotNull);
      expect(uiImage!.width, equals(512));
      expect(uiImage.height, equals(512));

      // Verify SVG generation embeds the actual crest
      final qrConfig = QrConfig(
        brandingPack: pack,
        logoType: logoType,
      );
      final svg = QrExportService.generateSvg(
        'https://rice.edu',
        qrConfig,
        logoBase64: base64String,
      );
      expect(svg, contains('<image href="data:image/png;base64,'));
    }
  });
}
