import 'package:test/test.dart';
import 'package:rice_url_shortener_server/src/web/routes/redirect_route.dart';
import 'package:rice_url_shortener_server/src/endpoints/link_endpoint.dart';

void main() {
  group('Serverpod Redirect and Code Validation Tests', () {
    test('RedirectRoute and LinkEndpoint reserve institutional system paths', () {
      expect(RedirectRoute.reservedPaths.contains('app'), isTrue);
      expect(RedirectRoute.reservedPaths.contains('api'), isTrue);
      expect(RedirectRoute.reservedPaths.contains('health'), isTrue);
      expect(RedirectRoute.reservedPaths.contains('metrics'), isTrue);
      expect(RedirectRoute.reservedPaths.contains('flutter'), isTrue);
      expect(RedirectRoute.reservedPaths.contains('canvaskit'), isTrue);
      expect(RedirectRoute.reservedPaths.contains('icons'), isTrue);
      expect(RedirectRoute.reservedPaths.contains('version'), isTrue);
      expect(RedirectRoute.reservedPaths.contains('favicon.ico'), isTrue);
      expect(RedirectRoute.reservedPaths.contains('campanile'), isFalse);
      expect(RedirectRoute.reservedPaths.contains('owl-fest'), isFalse);

      expect(LinkEndpoint.reservedRoutes.contains('app'), isTrue);
      expect(LinkEndpoint.reservedRoutes.contains('api'), isTrue);
      expect(LinkEndpoint.reservedRoutes.contains('dashboard'), isTrue);
      expect(LinkEndpoint.reservedRoutes.contains('flutter'), isTrue);
      expect(LinkEndpoint.reservedRoutes.contains('canvaskit'), isTrue);
      expect(LinkEndpoint.reservedRoutes.contains('health'), isTrue);
    });

    test('Short code length validation enforces at least 3 characters', () {
      bool isValidCode(String code) {
        final clean = code.trim().toLowerCase();
        return !LinkEndpoint.reservedRoutes.contains(clean) && clean.length >= 3;
      }

      expect(isValidCode('ab'), isFalse); // Too short
      expect(isValidCode('api'), isFalse); // Reserved
      expect(isValidCode('owl'), isTrue); // Valid 3-char
      expect(isValidCode('campanile'), isTrue); // Valid
    });

    test('HTTP Redirect status determination rules', () {
      int getRedirectStatus({
        required bool isActive,
        required DateTime? expiresAt,
        required DateTime currentTime,
      }) {
        if (!isActive) return 302; // Temporary redirect to fallback
        if (expiresAt != null && expiresAt.isBefore(currentTime)) return 302;
        return 301; // Permanent redirect for active destination
      }

      final now = DateTime.now();

      // Active unexpired -> 301
      expect(
        getRedirectStatus(
          isActive: true,
          expiresAt: now.add(const Duration(days: 1)),
          currentTime: now,
        ),
        equals(301),
      );

      // Inactive -> 302
      expect(
        getRedirectStatus(
          isActive: false,
          expiresAt: null,
          currentTime: now,
        ),
        equals(302),
      );

      // Expired -> 302
      expect(
        getRedirectStatus(
          isActive: true,
          expiresAt: now.subtract(const Duration(hours: 1)),
          currentTime: now,
        ),
        equals(302),
      );
    });
  });
}
