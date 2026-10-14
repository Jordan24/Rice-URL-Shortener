import 'package:flutter_test/flutter_test.dart';
import 'package:rice_url_shortener_client/rice_url_shortener_client.dart';
import 'package:rice_url_shortener/data/models/short_link.dart';
import 'package:rice_url_shortener/data/services/link_service.dart';
import 'package:rice_url_shortener/data/services/serverpod_link_service.dart';

void main() {
  group('ServerpodLinkService & ShortLinkRecord Tests', () {
    test('ShortLinkRecord serializes and deserializes correctly', () {
      final now = DateTime.now();
      final record = ShortLinkRecord(
        linkId: 'test1',
        userId: 'user123',
        userEmail: 'sammy@rice.edu',
        shortCode: 'test1',
        destinationUrl: 'https://rice.edu',
        fallbackUrl: 'https://rice.edu',
        expiresAt: null,
        isActive: true,
        clickCount: 10,
        lastClickedAt: now,
        createdAt: now,
        updatedAt: now,
        qrConfigJson: '{"fgColorHex":"#00205B"}',
      );

      final json = record.toJson();
      expect(json['shortCode'], 'test1');
      expect(json['clickCount'], 10);

      final parsed = ShortLinkRecord.fromJson(json);
      expect(parsed.linkId, 'test1');
      expect(parsed.userId, 'user123');
      expect(parsed.userEmail, 'sammy@rice.edu');
      expect(parsed.isActive, true);
    });

    test('ShortLinkRecord correctly handles Map and JSON for qrConfig', () {
      final now = DateTime.now();
      final recordFromMap = ShortLinkRecord.fromJson({
        'linkId': 'test2',
        'userId': 'user123',
        'userEmail': 'sammy@rice.edu',
        'shortCode': 'test2',
        'destinationUrl': 'https://rice.edu',
        'qrConfig': {'fgColorHex': '#00205B', 'style': 'dots', 'logoType': 'owl'},
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      expect(recordFromMap.qrConfigJson, isNotNull);
      expect(recordFromMap.qrConfigJson!.contains('#00205B'), isTrue);

      final service = ServerpodLinkService();
      expect(service, isA<LinkService>());
      service.dispose();
    });

    test('ServerpodLinkService enforces reserved routes and min length', () async {
      final service = ServerpodLinkService();

      expect(await service.isShortCodeAvailable('app'), isFalse);
      expect(await service.isShortCodeAvailable('api'), isFalse);
      expect(await service.isShortCodeAvailable('login'), isFalse);
      expect(await service.isShortCodeAvailable('health'), isFalse);
      expect(await service.isShortCodeAvailable('flutter'), isFalse);
      expect(await service.isShortCodeAvailable('canvaskit'), isFalse);
      expect(await service.isShortCodeAvailable('version'), isFalse);
      expect(await service.isShortCodeAvailable('hi'), isFalse); // < 3 chars
      expect(await service.isShortCodeAvailable('campanile'), isFalse); // already taken
      expect(await service.isShortCodeAvailable('owlfest26'), isTrue); // available

      service.dispose();
    });

    test('ServerpodLinkService handles optimistic link creation and streaming', () async {
      final service = ServerpodLinkService();
      final now = DateTime.now();
      final link = ShortLink(
        id: 'newlink',
        userId: 'user1',
        userEmail: 'user@rice.edu',
        shortCode: 'newlink',
        destinationUrl: 'https://rice.edu/test',
        createdAt: now,
        updatedAt: now,
      );

      final created = await service.createLink(link);
      expect(created.shortCode, 'newlink');
      expect(created.destinationUrl, 'https://rice.edu/test');

      // Test active toggle
      await service.toggleLinkActive('newlink', true);
      expect(await service.isShortCodeAvailable('newlink'), isFalse);

      // Test delete
      await service.deleteLink('newlink');

      service.dispose();
    });
  });
}
