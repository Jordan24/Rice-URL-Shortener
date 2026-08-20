import 'package:flutter_test/flutter_test.dart';
import 'package:rice_url_shortener/core/constants/rice_logos.dart';
import 'package:rice_url_shortener/data/models/qr_config.dart';
import 'package:rice_url_shortener/data/models/short_link.dart';
import 'package:rice_url_shortener/data/services/firestore_link_service.dart';
import 'package:rice_url_shortener/presentation/state/link_controller.dart';

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

  group('LinkController Search and Filtering Tests', () {
    late FirestoreLinkService linkService;
    late LinkController linkController;

    setUp(() async {
      linkService = FirestoreLinkService(firestore: null);
      linkController = LinkController(linkService: linkService);
      linkController.init('rice_demo_uid_1912');
      // Wait for mock links to populate
      await Future.delayed(Duration.zero);
    });

    test('Initial state populates links and filteredLinks matches allLinks', () {
      expect(linkController.allLinks.isNotEmpty, isTrue);
      expect(linkController.filteredLinks.length, equals(linkController.allLinks.length));
    });

    test('Filter by shortCode substring (case-insensitive)', () {
      linkController.setSearchQuery('CAMP');
      final filtered = linkController.filteredLinks;
      expect(filtered.length, equals(1));
      expect(filtered.first.shortCode, equals('campanile'));
    });

    test('Filter by destination URL substring', () {
      linkController.setSearchQuery('events.rice.edu');
      final filtered = linkController.filteredLinks;
      expect(filtered.length, equals(1));
      expect(filtered.first.shortCode, equals('fest26'));
    });

    test('Filter by full short URL', () {
      linkController.setSearchQuery('link.thejambers.com/campanile');
      final filtered = linkController.filteredLinks;
      expect(filtered.length, equals(1));
      expect(filtered.first.shortCode, equals('campanile'));
    });

    test('Filter by status (active vs expired)', () {
      linkController.setStatusFilter(LinkStatusFilter.active);
      for (final link in linkController.filteredLinks) {
        expect(link.isEffectivelyActive, isTrue);
      }

      linkController.setStatusFilter(LinkStatusFilter.expired);
      for (final link in linkController.filteredLinks) {
        expect(link.isExpired, isTrue);
      }
    });

    test('Clear filters resets search query and status filter', () {
      linkController.setSearchQuery('fest');
      linkController.setStatusFilter(LinkStatusFilter.expired);
      expect(linkController.searchQuery, equals('fest'));
      expect(linkController.statusFilter, equals(LinkStatusFilter.expired));

      linkController.clearFilters();
      expect(linkController.searchQuery, isEmpty);
      expect(linkController.statusFilter, equals(LinkStatusFilter.all));
      expect(linkController.filteredLinks.length, equals(linkController.allLinks.length));
    });

    test('Listeners are notified on search and status change', () {
      int notifyCount = 0;
      linkController.addListener(() {
        notifyCount++;
      });

      linkController.setSearchQuery('owl');
      expect(notifyCount, equals(1));

      linkController.setStatusFilter(LinkStatusFilter.active);
      expect(notifyCount, equals(2));

      linkController.clearFilters();
      expect(notifyCount, equals(3));
    });
  });
}
