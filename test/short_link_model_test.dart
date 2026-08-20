import 'package:flutter_test/flutter_test.dart';
import 'package:rice_url_shortener/core/constants/rice_logos.dart';
import 'package:rice_url_shortener/data/models/qr_config.dart';
import 'package:rice_url_shortener/data/models/short_link.dart';

void main() {
  group('ShortLink & QrConfig Model Tests', () {
    test('QrConfig default values are correct', () {
      const config = QrConfig();
      expect(config.fgColorHex, equals('#00205B'));
      expect(config.bgColorHex, equals('#FFFFFF'));
      expect(config.style, equals(QrStyle.square));
      expect(config.logoType, equals(RiceLogoType.shield));
      expect(config.isBgTransparent, isFalse);
    });

    test('QrConfig transparent background detection', () {
      const config = QrConfig(bgColorHex: '#00000000');
      expect(config.isBgTransparent, isTrue);
    });

    test('QrConfig serialization and deserialization', () {
      const config = QrConfig(
        fgColorHex: '#7C7E7F',
        bgColorHex: '#00143D',
        style: QrStyle.rounded,
        logoType: RiceLogoType.owl,
      );

      final map = config.toMap();
      final restored = QrConfig.fromMap(map);

      expect(restored.fgColorHex, equals('#7C7E7F'));
      expect(restored.bgColorHex, equals('#00143D'));
      expect(restored.style, equals(QrStyle.rounded));
      expect(restored.logoType, equals(RiceLogoType.owl));
    });

    test('ShortLink click analytics defaults and serialization', () {
      final now = DateTime.now();
      final link = ShortLink(
        id: 'campanile',
        userId: 'u1',
        userEmail: 'test@rice.edu',
        shortCode: 'campanile',
        destinationUrl: 'https://rice.edu',
        clickCount: 42,
        lastClickedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(link.clickCount, equals(42));
      expect(link.lastClickedAt, equals(now));

      final map = link.toMap();
      expect(map['clickCount'], equals(42));

      final restored = ShortLink.fromMap(map);
      expect(restored.clickCount, equals(42));
      expect(restored.shortCode, equals('campanile'));
    });

    test('ShortLink copyWith updates fields correctly', () {
      final now = DateTime.now();
      final link = ShortLink(
        id: 'campanile',
        userId: 'u1',
        userEmail: 'test@rice.edu',
        shortCode: 'campanile',
        destinationUrl: 'https://rice.edu',
        createdAt: now,
        updatedAt: now,
      );

      final updated = link.copyWith(
        clickCount: 10,
        lastClickedAt: now,
        destinationUrl: 'https://rice.edu/about',
      );

      expect(updated.clickCount, equals(10));
      expect(updated.lastClickedAt, equals(now));
      expect(updated.destinationUrl, equals('https://rice.edu/about'));
    });

    test('ShortLink expiration calculation', () {
      final activeLink = ShortLink(
        id: '1',
        userId: 'u1',
        userEmail: 'test@rice.edu',
        shortCode: 'fest',
        destinationUrl: 'https://rice.edu',
        expiresAt: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(activeLink.isExpired, isFalse);
      expect(activeLink.isEffectivelyActive, isTrue);

      final expiredLink = ShortLink(
        id: '2',
        userId: 'u1',
        userEmail: 'test@rice.edu',
        shortCode: 'old',
        destinationUrl: 'https://rice.edu',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(expiredLink.isExpired, isTrue);
      expect(expiredLink.isEffectivelyActive, isFalse);
    });

    test('ShortLink fullShortUrl generation', () {
      final link = ShortLink(
        id: '1',
        userId: 'u1',
        userEmail: 'test@rice.edu',
        shortCode: 'owl',
        destinationUrl: 'https://rice.edu',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(link.fullShortUrl(), equals('https://link.thejambers.com/owl'));
      expect(link.fullShortUrl('link.thejambers.com'), equals('https://link.thejambers.com/owl'));
      expect(link.fullShortUrl('rice.edu'), equals('https://rice.edu/owl'));
    });
  });
}
