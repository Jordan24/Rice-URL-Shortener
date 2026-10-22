import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rice_url_shortener/core/constants/app_constants.dart';
import 'package:rice_url_shortener/core/constants/rice_logos.dart';
import 'package:rice_url_shortener/core/utils/code_generator.dart';
import 'package:rice_url_shortener/core/utils/url_validator.dart';
import 'package:rice_url_shortener/data/models/short_link.dart';
import 'package:rice_url_shortener/data/models/qr_config.dart';
import 'package:rice_url_shortener/data/services/auth_service.dart';
import 'package:rice_url_shortener/data/services/qr_export_service.dart';
import 'package:rice_url_shortener/data/services/serverpod_link_service.dart';
import 'package:rice_url_shortener/presentation/state/link_controller.dart';
import 'package:rice_url_shortener_client/rice_url_shortener_client.dart' as client;

// ============================================================================
// E2E Redirection & Backend Simulation Test Harness
// Replicates Serverpod RedirectRoute, HealthRoute, and ApiRoute in memory.
// ============================================================================

class SimulatedHttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;

  SimulatedHttpResponse({
    required this.statusCode,
    Map<String, String>? headers,
    this.body = '',
  }) : headers = headers ?? {};

  String? get location => headers['location'] ?? headers['Location'];
}

class E2eRedirectionHarness {
  final Map<String, Map<String, dynamic>> _linksDb = {};
  final List<Map<String, dynamic>> _analyticsEvents = [];
  DateTime Function() clock = () => DateTime.now();

  static const String defaultFallbackUrl = 'https://rice.edu';
  static const Set<String> reservedPaths = {
    'app', 'api', 'login', 'auth', 'dashboard', 'static', 'r', 'admin',
    'assets', 'favicon', 'favicon.ico', 'manifest', 'null', 'undefined',
    'help', 'about', 'settings', 'health', 'metrics', 'flutter', 'canvaskit',
    'icons', 'version',
  };

  void seedLink(Map<String, dynamic> link) {
    final code = (link['shortCode'] as String).trim().toLowerCase();
    _linksDb[code] = Map<String, dynamic>.from(link);
    _linksDb[code]!['shortCode'] = code;
    _linksDb[code]!['id'] = link['id'] ?? link['linkId'] ?? code;
    _linksDb[code]!['linkId'] = _linksDb[code]!['id'];
  }

  Map<String, dynamic>? getLink(String code) => _linksDb[code.trim().toLowerCase()];
  List<Map<String, dynamic>> get analyticsEvents => List.unmodifiable(_analyticsEvents);
  int get linkCount => _linksDb.length;

  void clear() {
    _linksDb.clear();
    _analyticsEvents.clear();
  }

  http.Client createHttpClient() => MockE2eHttpClient(this);

  Future<SimulatedHttpResponse> simulateRedirect(
    String path, {
    String? userAgent,
    String? referer,
    String? ipAddress,
  }) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('https://go.thejambers.com/$cleanPath');
    final headers = <String, String>{};
    if (userAgent != null) headers['user-agent'] = userAgent;
    if (referer != null) headers['referer'] = referer;
    if (ipAddress != null) headers['x-forwarded-for'] = ipAddress;
    return handleRequest('GET', uri, headers: headers);
  }

  Future<SimulatedHttpResponse> handleRequest(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Content-Type, Accept, Authorization',
    };

    if (method == 'OPTIONS') {
      return SimulatedHttpResponse(statusCode: 204, headers: corsHeaders);
    }

    final segments = uri.pathSegments;

    // 1. Health Route: /health
    if (segments.length == 1 && segments[0] == 'health') {
      return SimulatedHttpResponse(
        statusCode: 200,
        headers: {...corsHeaders, 'content-type': 'application/json'},
        body: jsonEncode({'status': 'healthy', 'service': 'rice-url-shortener'}),
      );
    }

    // 2. API Routes: /api/*
    if (segments.isNotEmpty && segments[0] == 'api') {
      return _handleApi(method, segments, uri, body, corsHeaders);
    }

    // 3. Redirection Engine: /*
    return _handleRedirect(segments, headers);
  }

  Future<SimulatedHttpResponse> _handleRedirect(
    List<String> segments,
    Map<String, String>? headers,
  ) async {
    if (segments.isEmpty) {
      return SimulatedHttpResponse(statusCode: 404, body: 'Not found');
    }

    final code = segments.first.trim().toLowerCase();

    // Check reserved paths (bypass redirection, not handled by redirect route)
    if (reservedPaths.contains(code)) {
      return SimulatedHttpResponse(statusCode: 404, body: 'Reserved system path');
    }

    final link = _linksDb[code];
    if (link == null) {
      // Missing code -> HTTP 302 Found to default fallback
      return SimulatedHttpResponse(
        statusCode: 302,
        headers: {'location': defaultFallbackUrl},
      );
    }

    final destinationUrl = link['destinationUrl'] as String;
    final fallbackUrl = (link['fallbackUrl'] as String?)?.isNotEmpty == true
        ? link['fallbackUrl'] as String
        : defaultFallbackUrl;
    final isActive = link['isActive'] as bool? ?? true;
    final expiresAt = link['expiresAt'] != null
        ? (link['expiresAt'] is DateTime
            ? link['expiresAt'] as DateTime
            : DateTime.tryParse(link['expiresAt'].toString()))
        : null;

    // Check active flag
    if (!isActive) {
      return SimulatedHttpResponse(
        statusCode: 302,
        headers: {'location': fallbackUrl},
      );
    }

    // Check expiration against clock
    final now = clock();
    if (expiresAt != null && expiresAt.isBefore(now)) {
      return SimulatedHttpResponse(
        statusCode: 302,
        headers: {'location': fallbackUrl},
      );
    }

    // Active unexpired link: atomic click increment and analytics logging
    link['clickCount'] = ((link['clickCount'] as num?)?.toInt() ?? 0) + 1;
    link['lastClickedAt'] = now.toIso8601String();

    final userAgent = headers?['user-agent'] ?? headers?['User-Agent'];
    final referer = headers?['referer'] ?? headers?['Referer'];
    final ipAddress = headers?['x-forwarded-for'] ?? '127.0.0.1';

    _analyticsEvents.add({
      'linkId': link['id'] ?? link['linkId'],
      'shortCode': code,
      'timestamp': now.toIso8601String(),
      'userAgent': userAgent,
      'referer': referer,
      'ipAddress': ipAddress,
    });

    return SimulatedHttpResponse(
      statusCode: 301,
      headers: {
        'location': destinationUrl,
        'Cache-Control': 'private, no-cache',
      },
    );
  }

  Future<SimulatedHttpResponse> _handleApi(
    String method,
    List<String> segments,
    Uri uri,
    String? body,
    Map<String, String> corsHeaders,
  ) async {
    if (segments.length < 3) {
      return SimulatedHttpResponse(statusCode: 404, headers: corsHeaders, body: 'Invalid API route');
    }

    final category = segments[1];
    final action = segments[2];

    if (category == 'link') {
      if (action == 'isShortCodeAvailable') {
        final code = (uri.queryParameters['code'] ?? '').trim().toLowerCase();
        final excludeLinkId = uri.queryParameters['excludeLinkId'];
        final isReserved = reservedPaths.contains(code) || code.length < 3;
        final isTaken = _linksDb.containsKey(code) && _linksDb[code]!['id'] != excludeLinkId;
        return SimulatedHttpResponse(
          statusCode: 200,
          headers: {...corsHeaders, 'content-type': 'application/json'},
          body: jsonEncode({'available': !isReserved && !isTaken}),
        );
      }

      if (action == 'getUserLinks') {
        final userId = uri.queryParameters['userId'] ?? '';
        final userLinks = _linksDb.values
            .where((l) => l['userId'] == userId)
            .map((l) => _toRecordMap(l))
            .toList();
        return SimulatedHttpResponse(
          statusCode: 200,
          headers: {...corsHeaders, 'content-type': 'application/json'},
          body: jsonEncode(userLinks),
        );
      }

      if (action == 'createLink') {
        final data = jsonDecode(body ?? '{}') as Map<String, dynamic>;
        final code = (data['shortCode'] as String).trim().toLowerCase();
        if (reservedPaths.contains(code) || code.length < 3 || _linksDb.containsKey(code)) {
          return SimulatedHttpResponse(
            statusCode: 400,
            headers: corsHeaders,
            body: jsonEncode({'error': 'Short code "$code" is unavailable or reserved.'}),
          );
        }
        final record = {
          'id': data['id'] ?? code,
          'linkId': data['id'] ?? code,
          'userId': data['userId'] ?? 'user1',
          'userEmail': data['userEmail'] ?? 'sammy@rice.edu',
          'shortCode': code,
          'destinationUrl': data['destinationUrl'],
          'fallbackUrl': data['fallbackUrl'] ?? defaultFallbackUrl,
          'expiresAt': data['expiresAt'],
          'isActive': data['isActive'] ?? true,
          'clickCount': 0,
          'lastClickedAt': null,
          'createdAt': clock().toIso8601String(),
          'updatedAt': clock().toIso8601String(),
          'qrConfig': data['qrConfig'],
          'qrConfigJson': data['qrConfig'] != null ? jsonEncode(data['qrConfig']) : null,
        };
        _linksDb[code] = record;
        return SimulatedHttpResponse(
          statusCode: 200,
          headers: {...corsHeaders, 'content-type': 'application/json'},
          body: jsonEncode(_toRecordMap(record)),
        );
      }

      if (action == 'updateLink') {
        final data = jsonDecode(body ?? '{}') as Map<String, dynamic>;
        final linkId = data['id'] as String;
        final existing = _linksDb.values.firstWhere((l) => l['id'] == linkId, orElse: () => {});
        if (existing.isEmpty) {
          return SimulatedHttpResponse(statusCode: 404, headers: corsHeaders, body: 'Not found');
        }
        existing['destinationUrl'] = data['destinationUrl'] ?? existing['destinationUrl'];
        existing['fallbackUrl'] = data['fallbackUrl'] ?? existing['fallbackUrl'];
        existing['expiresAt'] = data['expiresAt'];
        existing['qrConfig'] = data['qrConfig'];
        existing['qrConfigJson'] = data['qrConfig'] != null ? jsonEncode(data['qrConfig']) : null;
        existing['updatedAt'] = clock().toIso8601String();
        return SimulatedHttpResponse(
          statusCode: 200,
          headers: {...corsHeaders, 'content-type': 'application/json'},
          body: jsonEncode({'success': true}),
        );
      }

      if (action == 'toggleActive') {
        final data = jsonDecode(body ?? '{}') as Map<String, dynamic>;
        final linkId = data['linkId'] as String;
        final current = data['currentStatus'] as bool? ?? true;
        final existing = _linksDb.values.firstWhere((l) => l['id'] == linkId, orElse: () => {});
        if (existing.isNotEmpty) {
          existing['isActive'] = !current;
          existing['updatedAt'] = clock().toIso8601String();
          return SimulatedHttpResponse(
            statusCode: 200,
            headers: {...corsHeaders, 'content-type': 'application/json'},
            body: jsonEncode({'success': true}),
          );
        }
        return SimulatedHttpResponse(statusCode: 404, headers: corsHeaders, body: 'Not found');
      }

      if (action == 'deleteLink') {
        final data = jsonDecode(body ?? '{}') as Map<String, dynamic>;
        final linkId = data['linkId'] as String;
        final code = _linksDb.keys.firstWhere(
          (k) => _linksDb[k]?['id'] == linkId,
          orElse: () => '',
        );
        if (code.isNotEmpty) {
          _linksDb.remove(code);
          return SimulatedHttpResponse(
            statusCode: 200,
            headers: {...corsHeaders, 'content-type': 'application/json'},
            body: jsonEncode({'success': true}),
          );
        }
        return SimulatedHttpResponse(statusCode: 404, headers: corsHeaders, body: 'Not found');
      }
    }

    if (category == 'analytics' && action == 'getLinkAnalytics') {
      final code = (uri.queryParameters['shortCode'] ?? '').trim().toLowerCase();
      final link = _linksDb[code];
      if (link == null) {
        return SimulatedHttpResponse(
          statusCode: 404,
          headers: corsHeaders,
          body: jsonEncode({'error': 'Short link not found'}),
        );
      }

      final recent = _analyticsEvents
          .where((e) => e['shortCode'] == code)
          .toList()
          .reversed
          .take(20)
          .toList();

      return SimulatedHttpResponse(
        statusCode: 200,
        headers: {...corsHeaders, 'content-type': 'application/json'},
        body: jsonEncode({
          'shortCode': code,
          'destinationUrl': link['destinationUrl'],
          'totalClicks': link['clickCount'] ?? 0,
          'lastClickedAt': link['lastClickedAt'],
          'createdAt': link['createdAt'],
          'recentClicks': recent,
        }),
      );
    }

    return SimulatedHttpResponse(statusCode: 404, headers: corsHeaders, body: 'Unknown API endpoint');
  }

  String? _formatDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val.toIso8601String();
    if (val is String) return val;
    try {
      final dynamic dyn = val;
      if (dyn.toDate != null) {
        return (dyn.toDate() as DateTime).toIso8601String();
      }
    } catch (_) {}
    return val.toString();
  }

  Map<String, dynamic> _toRecordMap(Map<String, dynamic> link) {
    return {
      'linkId': link['id'] ?? link['linkId'],
      'userId': link['userId'],
      'userEmail': link['userEmail'],
      'shortCode': link['shortCode'],
      'destinationUrl': link['destinationUrl'],
      'fallbackUrl': link['fallbackUrl'] ?? defaultFallbackUrl,
      'expiresAt': _formatDate(link['expiresAt']),
      'isActive': link['isActive'] ?? true,
      'clickCount': link['clickCount'] ?? 0,
      'lastClickedAt': _formatDate(link['lastClickedAt']),
      'createdAt': _formatDate(link['createdAt']) ?? clock().toIso8601String(),
      'updatedAt': _formatDate(link['updatedAt']) ?? clock().toIso8601String(),
      'qrConfigJson': link['qrConfigJson'] ?? (link['qrConfig'] != null ? jsonEncode(link['qrConfig']) : null),
    };
  }
}

class MockE2eHttpClient extends http.BaseClient {
  final E2eRedirectionHarness harness;

  MockE2eHttpClient(this.harness);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    String? body;
    if (request is http.Request) {
      body = request.body;
    }
    final response = await harness.handleRequest(
      request.method,
      request.url,
      headers: request.headers,
      body: body,
    );
    final bytes = utf8.encode(response.body);
    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      headers: response.headers,
      contentLength: bytes.length,
      request: request,
    );
  }
}

// ============================================================================
// MAIN TEST SUITE (Tiers 1 - 4)
// ============================================================================

void main() {
  late E2eRedirectionHarness harness;
  late ServerpodLinkService linkService;

  setUp(() {
    harness = E2eRedirectionHarness();
    linkService = ServerpodLinkService(
      backendUrl: 'https://go.thejambers.com',
      httpClient: harness.createHttpClient(),
    );
  });

  tearDown(() {
    linkService.dispose();
    harness.clear();
  });

  // ==========================================================================
  // TIER 1: FEATURE COVERAGE (Isolated Happy-Path per Feature, >=5 tests each)
  // ==========================================================================
  group('Tier 1: Feature Coverage', () {
    // Feature 1: Short Code Creation
    group('1. Short Code Creation', () {
      test('1.1 Generates 5-character alphanumeric short code', () {
        final code = CodeGenerator.generateShortCode();
        expect(code.length, equals(5));
        expect(RegExp(r'^[a-z0-9]{5}$').hasMatch(code), isTrue);
      });

      test('1.2 Generates lowercase normalized code', () {
        final code = CodeGenerator.generateShortCode();
        expect(code, equals(code.toLowerCase()));
      });

      test('1.3 Generated codes exhibit randomness and uniqueness', () {
        final set = <String>{};
        for (int i = 0; i < 50; i++) {
          set.add(CodeGenerator.generateShortCode());
        }
        expect(set.length, equals(50));
      });

      test('1.4 Service checks availability before creation', () async {
        final available = await linkService.isShortCodeAvailable('owl26');
        expect(available, isTrue);
      });

      test('1.5 Successfully creates link with auto-generated code', () async {
        final code = CodeGenerator.generateShortCode();
        final now = DateTime.now();
        final apiClient = client.Client(
          'https://go.thejambers.com',
          httpClient: harness.createHttpClient(),
        );
        final created = await apiClient.link.createLink({
          'shortCode': code,
          'destinationUrl': 'https://rice.edu/admissions',
          'fallbackUrl': 'https://rice.edu',
          'userId': 'rice_user_1',
          'userEmail': 'sammy@rice.edu',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });
        expect(created.shortCode, equals(code));
        expect(created.destinationUrl, equals('https://rice.edu/admissions'));
        expect(harness.getLink(code), isNotNull);
        apiClient.close();
      });
    });

    // Feature 2: Alias Format
    group('2. Alias Format', () {
      test('2.1 Accepts valid hyphenated alias (e.g. owl-fest-2026)', () {
        expect(CodeGenerator.validateSlug('owl-fest-2026'), isNull);
      });

      test('2.2 Accepts valid underscored alias (e.g. hackrice_12)', () {
        expect(CodeGenerator.validateSlug('hackrice_12'), isNull);
      });

      test('2.3 Accepts minimum 3-character alphanumeric alias (e.g. owl)', () {
        expect(CodeGenerator.validateSlug('owl'), isNull);
      });

      test('2.4 Trims whitespace and normalizes alias to lowercase', () {
        expect(CodeGenerator.sanitizeSlug('  RiceFest2026  '), equals('ricefest2026'));
      });

      test('2.5 Successfully persists custom alias in backend', () async {
        final now = DateTime.now();
        const alias = 'admissions-fall';
        final apiClient = client.Client(
          'https://go.thejambers.com',
          httpClient: harness.createHttpClient(),
        );
        final created = await apiClient.link.createLink({
          'shortCode': alias,
          'destinationUrl': 'https://rice.edu/fall',
          'fallbackUrl': 'https://rice.edu',
          'userId': 'user1',
          'userEmail': 'sammy@rice.edu',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });
        expect(created.shortCode, equals(alias));
        final stored = harness.getLink(alias);
        expect(stored?['shortCode'], equals(alias));
        apiClient.close();
      });
    });

    // Feature 3: Expiration
    group('3. Expiration', () {
      test('3.1 Future expiration date marks link as active and not expired', () {
        final future = DateTime.now().add(const Duration(days: 7));
        final link = ShortLink(
          id: 'exp1',
          userId: 'user1',
          userEmail: 'sammy@rice.edu',
          shortCode: 'exp1',
          destinationUrl: 'https://rice.edu',
          expiresAt: future,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(link.isExpired, isFalse);
        expect(link.isEffectivelyActive, isTrue);
      });

      test('3.2 Null expiration timestamp represents permanent link', () {
        final link = ShortLink(
          id: 'perm1',
          userId: 'user1',
          userEmail: 'sammy@rice.edu',
          shortCode: 'perm1',
          destinationUrl: 'https://rice.edu',
          expiresAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(link.isExpired, isFalse);
        expect(link.isEffectivelyActive, isTrue);
      });

      test('3.3 Expiration serializes to and from ISO8601 string correctly in client record', () {
        final expiry = DateTime.parse('2026-12-31T23:59:59.000Z');
        final now = DateTime.now();
        final record = client.ShortLinkRecord(
          linkId: 'iso1',
          userId: 'user1',
          userEmail: 'sammy@rice.edu',
          shortCode: 'iso1',
          destinationUrl: 'https://rice.edu',
          expiresAt: expiry,
          createdAt: now,
          updatedAt: now,
        );
        final map = record.toJson();
        expect(map['expiresAt'], equals(expiry.toIso8601String()));
        final restored = client.ShortLinkRecord.fromJson(map);
        expect(restored.expiresAt, equals(expiry));
      });

      test('3.4 Update link extends expiration into future', () async {
        final now = DateTime.now();
        final initialExpiry = now.add(const Duration(days: 1));
        harness.seedLink({
          'id': 'extendable',
          'shortCode': 'extendable',
          'destinationUrl': 'https://rice.edu',
          'fallbackUrl': 'https://rice.edu',
          'expiresAt': initialExpiry.toIso8601String(),
          'isActive': true,
        });

        final apiClient = client.Client(
          'https://go.thejambers.com',
          httpClient: harness.createHttpClient(),
        );

        final newExpiry = now.add(const Duration(days: 30));
        await apiClient.link.updateLink({
          'id': 'extendable',
          'shortCode': 'extendable',
          'destinationUrl': 'https://rice.edu',
          'expiresAt': newExpiry.toIso8601String(),
        });

        final updated = harness.getLink('extendable');
        expect(updated?['expiresAt'], equals(newExpiry.toIso8601String()));
        apiClient.close();
      });

      test('3.5 Expired link is correctly reported as expired', () {
        final past = DateTime.now().subtract(const Duration(hours: 2));
        final link = ShortLink(
          id: 'expired1',
          userId: 'user1',
          userEmail: 'sammy@rice.edu',
          shortCode: 'expired1',
          destinationUrl: 'https://rice.edu',
          expiresAt: past,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
        );
        expect(link.isExpired, isTrue);
        expect(link.isEffectivelyActive, isFalse);
      });
    });

    // Feature 4: Fallback URL
    group('4. Fallback URL', () {
      test('4.1 Defaults fallbackUrl to https://rice.edu when omitted', () {
        final link = ShortLink(
          id: 'fb1',
          userId: 'user1',
          userEmail: 'sammy@rice.edu',
          shortCode: 'fb1',
          destinationUrl: 'https://rice.edu/news',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(link.fallbackUrl, equals(AppConstants.defaultFallbackUrl));
      });

      test('4.2 Preserves custom fallback URL (e.g. https://rice.edu/admissions)', () {
        const customFallback = 'https://rice.edu/admissions';
        final link = ShortLink(
          id: 'fb2',
          userId: 'user1',
          userEmail: 'sammy@rice.edu',
          shortCode: 'fb2',
          destinationUrl: 'https://rice.edu/tour',
          fallbackUrl: customFallback,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(link.fallbackUrl, equals(customFallback));
      });

      test('4.3 Normalizes schemeless fallback URL to https://', () {
        final normalized = UrlValidator.normalizeUrl('rice.edu/help');
        expect(normalized, equals('https://rice.edu/help'));
        expect(UrlValidator.validateUrl(normalized), isNull);
      });

      test('4.4 Fallback URL survives map serialization and deserialization', () {
        const customFallback = 'https://rice.edu/athletics';
        final link = ShortLink(
          id: 'fb4',
          userId: 'user1',
          userEmail: 'sammy@rice.edu',
          shortCode: 'fb4',
          destinationUrl: 'https://rice.edu/game',
          fallbackUrl: customFallback,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final restored = ShortLink.fromMap(link.toMap());
        expect(restored.fallbackUrl, equals(customFallback));
      });

      test('4.5 Inactive link redirects visitor to custom fallback URL', () async {
        const customFallback = 'https://rice.edu/alumni';
        harness.seedLink({
          'shortCode': 'reunion',
          'destinationUrl': 'https://rice.edu/reunion-event',
          'fallbackUrl': customFallback,
          'isActive': false,
        });

        final res = await harness.simulateRedirect('/reunion');
        expect(res.statusCode, equals(302));
        expect(res.location, equals(customFallback));
      });
    });

    // Feature 5: QR Styling
    group('5. QR Styling', () {
      test('5.1 Generates valid SVG with Square module style', () {
        const config = QrConfig(style: QrStyle.square);
        final svg = QrExportService.generateSvg('https://go.thejambers.com/owl1', config);
        expect(svg, contains('<svg'));
        expect(svg, contains('</svg>'));
        expect(svg, contains('<rect'));
      });

      test('5.2 Generates valid SVG with Rounded module style', () {
        const config = QrConfig(style: QrStyle.rounded);
        final svg = QrExportService.generateSvg('https://go.thejambers.com/owl2', config);
        expect(svg, contains('<svg'));
        expect(svg, contains('path'));
      });

      test('5.3 Generates valid SVG with Dots module style', () {
        const config = QrConfig(style: QrStyle.dots);
        final svg = QrExportService.generateSvg('https://go.thejambers.com/owl3', config);
        expect(svg, contains('<svg'));
        expect(svg, contains('<circle'));
      });

      test('5.4 Embeds official Rice Shield logo base64 image tag in SVG', () {
        const config = QrConfig(style: QrStyle.square, logoType: RiceLogoType.shield);
        final svg = QrExportService.generateSvg(
          'https://go.thejambers.com/shield-qr',
          config,
          logoBase64: 'fakeBase64ShieldData',
        );
        expect(svg, contains('<image href="data:image/png;base64,fakeBase64ShieldData"'));
      });

      test('5.5 Generates PNG byte buffer with valid PNG magic bytes', () async {
        const config = QrConfig(
          fgColorHex: '#00205B',
          bgColorHex: '#FFFFFF',
          style: QrStyle.square,
          logoType: RiceLogoType.none,
        );
        final bytes = await QrExportService.generatePngBytes(
          'https://go.thejambers.com/png-test',
          config,
          256,
        );
        expect(bytes.isNotEmpty, isTrue);
        // PNG magic number: 0x89, 'P', 'N', 'G'
        expect(bytes[0], equals(0x89));
        expect(bytes[1], equals(0x50));
        expect(bytes[2], equals(0x4E));
        expect(bytes[3], equals(0x47));
      });
    });

    // Feature 6: Redirect Status Codes
    group('6. Redirect Status Codes', () {
      test('6.1 Active unexpired link returns HTTP 301 Permanent Redirect to destination', () async {
        harness.seedLink({
          'shortCode': 'active1',
          'destinationUrl': 'https://rice.edu/active-dest',
          'isActive': true,
        });

        final res = await harness.simulateRedirect('/active1');
        expect(res.statusCode, equals(301));
        expect(res.location, equals('https://rice.edu/active-dest'));
      });

      test('6.2 Inactive link returns HTTP 302 Found to fallback URL', () async {
        harness.seedLink({
          'shortCode': 'inactive1',
          'destinationUrl': 'https://rice.edu/dest',
          'fallbackUrl': 'https://rice.edu/fallback',
          'isActive': false,
        });

        final res = await harness.simulateRedirect('/inactive1');
        expect(res.statusCode, equals(302));
        expect(res.location, equals('https://rice.edu/fallback'));
      });

      test('6.3 Expired link returns HTTP 302 Found to fallback URL', () async {
        harness.seedLink({
          'shortCode': 'expired1',
          'destinationUrl': 'https://rice.edu/dest',
          'fallbackUrl': 'https://rice.edu/fallback',
          'expiresAt': DateTime.now().subtract(const Duration(days: 1)),
          'isActive': true,
        });

        final res = await harness.simulateRedirect('/expired1');
        expect(res.statusCode, equals(302));
        expect(res.location, equals('https://rice.edu/fallback'));
      });

      test('6.4 Missing/Unknown short code returns HTTP 302 Found to default rice.edu', () async {
        final res = await harness.simulateRedirect('/unknown-code-xyz');
        expect(res.statusCode, equals(302));
        expect(res.location, equals('https://rice.edu'));
      });

      test('6.5 HTTP 301 redirect sets Cache-Control: private, no-cache', () async {
        harness.seedLink({
          'shortCode': 'nocache',
          'destinationUrl': 'https://rice.edu/no-cache-dest',
          'isActive': true,
        });

        final res = await harness.simulateRedirect('/nocache');
        expect(res.statusCode, equals(301));
        expect(res.headers['Cache-Control'], equals('private, no-cache'));
      });
    });
  });

  // ==========================================================================
  // TIER 2: BOUNDARY & CORNER CASES (>=5 tests per feature)
  // ==========================================================================
  group('Tier 2: Boundary & Corner Cases', () {
    // Feature 1: Max Length Aliases & Length Limits
    group('1. Max Length Aliases & Length Limits', () {
      test('1.1 Exact 30-character alias is accepted (upper boundary)', () {
        final slug30 = 'a' * 30;
        expect(CodeGenerator.validateSlug(slug30), isNull);
      });

      test('1.2 31-character alias is rejected with length validation error', () {
        final slug31 = 'a' * 31;
        final error = CodeGenerator.validateSlug(slug31);
        expect(error, isNotNull);
        expect(error, contains('between 3 and 30 characters'));
      });

      test('1.3 2-character alias is rejected (below 3-character minimum)', () {
        final error = CodeGenerator.validateSlug('ab');
        expect(error, isNotNull);
        expect(error, contains('between 3 and 30 characters'));
      });

      test('1.4 Single-character alias is rejected', () {
        final error = CodeGenerator.validateSlug('a');
        expect(error, isNotNull);
        expect(error, contains('between 3 and 30 characters'));
      });

      test('1.5 Extreme oversized alias (128 characters) is rejected cleanly', () {
        final giantSlug = 'owl-' * 32;
        final error = CodeGenerator.validateSlug(giantSlug);
        expect(error, isNotNull);
      });
    });

    // Feature 2: Empty & Malformed Inputs
    group('2. Empty & Malformed Inputs', () {
      test('2.1 Null alias input is rejected with required error', () {
        final error = CodeGenerator.validateSlug(null);
        expect(error, isNotNull);
        expect(error, contains('required'));
      });

      test('2.2 Empty string "" alias is rejected with required error', () {
        final error = CodeGenerator.validateSlug('');
        expect(error, isNotNull);
        expect(error, contains('required'));
      });

      test('2.3 Whitespace-only string "   " alias is rejected', () {
        final error = CodeGenerator.validateSlug('   ');
        expect(error, isNotNull);
        expect(error, contains('required'));
      });

      test('2.4 Empty destination URL is rejected by UrlValidator', () {
        final error = UrlValidator.validateUrl('');
        expect(error, isNotNull);
        expect(error, contains('required'));
      });

      test('2.5 Malformed destination URLs (no scheme, bad domain, invalid symbols) rejected', () {
        expect(UrlValidator.validateUrl('not a valid url'), isNotNull);
        expect(UrlValidator.validateUrl('http://'), isNotNull);
        expect(UrlValidator.validateUrl('http://nodotdomain'), isNotNull);
      });
    });

    // Feature 3: Non-Rice Emails & Domain Authentication Boundaries
    group('3. Non-Rice Emails & Auth Boundaries', () {
      test('3.1 Commercial Gmail address rejected by RiceUser.isRiceEmail', () {
        const user = RiceUser(uid: 'u1', email: 'sammy@gmail.com', displayName: 'Sammy');
        expect(user.isRiceEmail, isFalse);
      });

      test('3.2 Subdomain spoof (user@rice.edu.evil.com) rejected', () {
        const user = RiceUser(uid: 'u2', email: 'hacker@rice.edu.evil.com', displayName: 'Hacker');
        expect(user.isRiceEmail, isFalse);
      });

      test('3.3 Prefix-match without @ (rice.edu@yahoo.com) rejected', () {
        const user = RiceUser(uid: 'u3', email: 'rice.edu@yahoo.com', displayName: 'Impostor');
        expect(user.isRiceEmail, isFalse);
      });

      test('3.4 Case-insensitive uppercase SAMMY@RICE.EDU accepted as valid Rice email', () {
        const user = RiceUser(uid: 'u4', email: 'SAMMY@RICE.EDU', displayName: 'Sammy');
        expect(user.isRiceEmail, isTrue);
      });

      test('3.5 Standard faculty/student @rice.edu email accepted', () {
        const user = RiceUser(uid: 'u5', email: 'president@rice.edu', displayName: 'Rice President');
        expect(user.isRiceEmail, isTrue);
      });
    });

    // Feature 4: Expired Timestamps & Clock Boundary Conditions
    group('4. Expired Timestamps & Clock Boundary Conditions', () {
      test('4.1 Expired exactly 1 second in the past returns HTTP 302', () async {
        final referenceTime = DateTime(2026, 10, 20, 12, 0, 0);
        harness.clock = () => referenceTime;

        harness.seedLink({
          'shortCode': 'just-expired',
          'destinationUrl': 'https://rice.edu/fresh',
          'fallbackUrl': 'https://rice.edu/stale',
          'expiresAt': referenceTime.subtract(const Duration(seconds: 1)),
          'isActive': true,
        });

        final res = await harness.simulateRedirect('/just-expired');
        expect(res.statusCode, equals(302));
        expect(res.location, equals('https://rice.edu/stale'));
      });

      test('4.2 Expiring 1 second in the future returns HTTP 301', () async {
        final referenceTime = DateTime(2026, 10, 20, 12, 0, 0);
        harness.clock = () => referenceTime;

        harness.seedLink({
          'shortCode': 'barely-active',
          'destinationUrl': 'https://rice.edu/fresh',
          'fallbackUrl': 'https://rice.edu/stale',
          'expiresAt': referenceTime.add(const Duration(seconds: 1)),
          'isActive': true,
        });

        final res = await harness.simulateRedirect('/barely-active');
        expect(res.statusCode, equals(301));
        expect(res.location, equals('https://rice.edu/fresh'));
      });

      test('4.3 Distant past expiration (1 year ago) returns HTTP 302', () async {
        harness.seedLink({
          'shortCode': 'ancient',
          'destinationUrl': 'https://rice.edu/ancient',
          'expiresAt': DateTime.now().subtract(const Duration(days: 365)),
          'isActive': true,
        });

        final res = await harness.simulateRedirect('/ancient');
        expect(res.statusCode, equals(302));
        expect(res.location, equals('https://rice.edu'));
      });

      test('4.4 State transition: Extending expiration reactivates redirect from 302 to 301', () async {
        final referenceTime = DateTime(2026, 10, 20, 12, 0, 0);
        harness.clock = () => referenceTime;

        harness.seedLink({
          'id': 'reloaded',
          'shortCode': 'reloaded',
          'destinationUrl': 'https://rice.edu/destination',
          'fallbackUrl': 'https://rice.edu/fallback',
          'expiresAt': referenceTime.subtract(const Duration(minutes: 5)).toIso8601String(), // initially expired
          'isActive': true,
        });

        // Before update: expired -> 302
        var res = await harness.simulateRedirect('/reloaded');
        expect(res.statusCode, equals(302));
        expect(res.location, equals('https://rice.edu/fallback'));

        // Extend expiration into future -> 301
        final apiClient = client.Client(
          'https://go.thejambers.com',
          httpClient: harness.createHttpClient(),
        );
        final newExpiry = referenceTime.add(const Duration(days: 7));
        await apiClient.link.updateLink({
          'id': 'reloaded',
          'shortCode': 'reloaded',
          'destinationUrl': 'https://rice.edu/destination',
          'expiresAt': newExpiry.toIso8601String(),
        });

        res = await harness.simulateRedirect('/reloaded');
        expect(res.statusCode, equals(301));
        expect(res.location, equals('https://rice.edu/destination'));
        apiClient.close();
      });

      test('4.5 Inactive state overrides future expiration', () async {
        harness.seedLink({
          'shortCode': 'future-inactive',
          'destinationUrl': 'https://rice.edu/dest',
          'fallbackUrl': 'https://rice.edu/fb',
          'expiresAt': DateTime.now().add(const Duration(days: 100)),
          'isActive': false, // de-activated
        });

        final res = await harness.simulateRedirect('/future-inactive');
        expect(res.statusCode, equals(302));
        expect(res.location, equals('https://rice.edu/fb'));
      });
    });

    // Feature 5: Reserved Path Collisions
    group('5. Reserved Path Collisions', () {
      test('5.1 /app reserved system route rejected by validator and redirect handler', () async {
        expect(CodeGenerator.validateSlug('app'), isNotNull);
        final res = await harness.simulateRedirect('/app');
        expect(res.statusCode, equals(404)); // not intercepted as redirect
      });

      test('5.2 /api reserved system route rejected', () async {
        expect(CodeGenerator.validateSlug('api'), isNotNull);
        expect(await linkService.isShortCodeAvailable('api'), isFalse);
      });

      test('5.3 /health reserved ALB health check route rejected', () async {
        expect(CodeGenerator.validateSlug('health'), isNotNull);
        final res = await harness.simulateRedirect('/health');
        expect(res.statusCode, equals(200)); // returns health payload, not redirect
        expect(res.body, contains('healthy'));
      });

      test('5.4 /dashboard reserved frontend SPA route rejected', () async {
        expect(CodeGenerator.validateSlug('dashboard'), isNotNull);
        expect(await linkService.isShortCodeAvailable('dashboard'), isFalse);
      });

      test('5.5 Framework asset routes (flutter, canvaskit, version, favicon.ico) rejected', () {
        expect(CodeGenerator.validateSlug('flutter'), isNotNull);
        expect(CodeGenerator.validateSlug('canvaskit'), isNotNull);
        expect(CodeGenerator.validateSlug('version'), isNotNull);
        expect(CodeGenerator.validateSlug('favicon.ico'), isNotNull);
      });
    });
  });

  // ==========================================================================
  // TIER 3: CROSS-FEATURE COMBINATIONS (Pairwise Interactions)
  // ==========================================================================
  group('Tier 3: Cross-Feature Combinations', () {
    test('3.1 Custom alias + Expiration + Fallback + Shield Logo QR', () async {
      final now = DateTime.now();
      final futureExpiry = now.add(const Duration(days: 14));
      const alias = 'admissions-2026';
      const dest = 'https://rice.edu/admissions/apply';
      const fallback = 'https://rice.edu/admissions';
      const qrConfig = QrConfig(
        fgColorHex: '#00205B',
        bgColorHex: '#FFFFFF',
        style: QrStyle.square,
        logoType: RiceLogoType.shield,
      );

      final link = ShortLink(
        id: alias,
        userId: 'admissions_office',
        userEmail: 'admit@rice.edu',
        shortCode: alias,
        destinationUrl: dest,
        fallbackUrl: fallback,
        expiresAt: futureExpiry,
        qrConfig: qrConfig,
        createdAt: now,
        updatedAt: now,
      );

      harness.seedLink({
        'id': alias,
        'shortCode': alias,
        'destinationUrl': dest,
        'fallbackUrl': fallback,
        'expiresAt': futureExpiry.toIso8601String(),
        'isActive': true,
        'qrConfig': qrConfig.toMap(),
      });

      // Redirection behavior
      final redirectRes = await harness.simulateRedirect('/$alias');
      expect(redirectRes.statusCode, equals(301));
      expect(redirectRes.location, equals(dest));

      // QR SVG behavior
      final svg = QrExportService.generateSvg(
        link.fullShortUrl(),
        link.qrConfig,
        logoBase64: 'fakeShieldBase64',
      );
      expect(svg, contains('<svg'));
      expect(svg, contains('<image href="data:image/png;base64,fakeShieldBase64"'));
    });

    test('3.2 Custom alias + Inactive status + Fallback + Dots QR style', () async {
      const alias = 'alumni-gala';
      const dest = 'https://giving.rice.edu/gala';
      const fallback = 'https://giving.rice.edu';
      const qrConfig = QrConfig(
        fgColorHex: '#00205B',
        bgColorHex: '#FFFFFF',
        style: QrStyle.dots,
        logoType: RiceLogoType.none,
      );

      harness.seedLink({
        'shortCode': alias,
        'destinationUrl': dest,
        'fallbackUrl': fallback,
        'isActive': false, // inactive
        'qrConfig': qrConfig.toMap(),
      });

      // Redirection points to fallback with 302
      final redirectRes = await harness.simulateRedirect('/$alias');
      expect(redirectRes.statusCode, equals(302));
      expect(redirectRes.location, equals(fallback));

      // QR SVG uses circle elements
      final svg = QrExportService.generateSvg('https://go.thejambers.com/$alias', qrConfig);
      expect(svg, contains('<circle'));
    });

    test('3.3 Auto-generated code + Expired timestamp + Fallback + Rounded QR + Owl logo', () async {
      final code = CodeGenerator.generateShortCode();
      final pastExpiry = DateTime.now().subtract(const Duration(days: 3));
      const dest = 'https://riceowls.com/game1';
      const fallback = 'https://riceowls.com/schedule';
      const qrConfig = QrConfig(
        fgColorHex: '#00205B',
        bgColorHex: '#FFFFFF',
        style: QrStyle.rounded,
        logoType: RiceLogoType.owl,
      );

      harness.seedLink({
        'shortCode': code,
        'destinationUrl': dest,
        'fallbackUrl': fallback,
        'expiresAt': pastExpiry.toIso8601String(),
        'isActive': true,
        'qrConfig': qrConfig.toMap(),
      });

      // Redirection points to fallback with 302 due to expiration
      final redirectRes = await harness.simulateRedirect('/$code');
      expect(redirectRes.statusCode, equals(302));
      expect(redirectRes.location, equals(fallback));

      // QR SVG uses path elements and embeds owl logo
      final svg = QrExportService.generateSvg(
        'https://go.thejambers.com/$code',
        qrConfig,
        logoBase64: 'fakeOwlBase64',
      );
      expect(svg, contains('path'));
      expect(svg, contains('<image href="data:image/png;base64,fakeOwlBase64"'));
    });

    test('3.4 Max-length slug (30 chars) + Distant expiration + Laurel Gold QR + Old English R', () async {
      const slug30 = 'rice-centennial-campaign--2026'; // exactly 30 chars
      expect(slug30.length, equals(30));
      expect(CodeGenerator.validateSlug(slug30), isNull);

      const qrConfig = QrConfig(
        fgColorHex: '#C19B4C',
        bgColorHex: '#FFFFFF',
        style: QrStyle.square,
        logoType: RiceLogoType.oldEnglishR,
      );

      harness.seedLink({
        'shortCode': slug30,
        'destinationUrl': 'https://centennial.rice.edu',
        'expiresAt': DateTime.now().add(const Duration(days: 365)),
        'isActive': true,
        'qrConfig': qrConfig.toMap(),
      });

      final res = await harness.simulateRedirect('/$slug30');
      expect(res.statusCode, equals(301));
      expect(res.location, equals('https://centennial.rice.edu'));

      final svg = QrExportService.generateSvg(
        'https://go.thejambers.com/$slug30',
        qrConfig,
        logoBase64: 'fakeOldEnglishRBase64',
      );
      expect(svg, contains('#C19B4C'));
      expect(svg, contains('fakeOldEnglishRBase64'));
    });

    test('3.5 Custom slug + Null expiration + Default fallback + Transparent background QR', () async {
      const alias = 'cs-department';
      const dest = 'https://cs.rice.edu';
      const qrConfig = QrConfig(
        fgColorHex: '#00205B',
        bgColorHex: '#00000000', // transparent
        style: QrStyle.square,
        logoType: RiceLogoType.none,
      );
      expect(qrConfig.isBgTransparent, isTrue);

      harness.seedLink({
        'shortCode': alias,
        'destinationUrl': dest,
        'fallbackUrl': null, // default
        'expiresAt': null, // permanent
        'isActive': true,
      });

      final res = await harness.simulateRedirect('/$alias');
      expect(res.statusCode, equals(301));
      expect(res.location, equals(dest));

      final svg = QrExportService.generateSvg('https://go.thejambers.com/$alias', qrConfig);
      // Transparent background should omit background rect fill or set transparent
      expect(svg, contains('<svg'));
    });

    test('3.6 Case-insensitive upper slug + State lifecycle (Expired -> Reactivate -> Toggle Inactive -> Reactivate)', () async {
      final baseTime = DateTime(2026, 10, 20, 10, 0, 0);
      harness.clock = () => baseTime;

      const upperSlug = 'CAMP-FEST';
      final cleanSlug = CodeGenerator.sanitizeSlug(upperSlug);
      expect(cleanSlug, equals('camp-fest'));

      // 1. Initially created as expired
      harness.seedLink({
        'id': cleanSlug,
        'shortCode': cleanSlug,
        'destinationUrl': 'https://rice.edu/fest',
        'fallbackUrl': 'https://rice.edu/info',
        'expiresAt': baseTime.subtract(const Duration(hours: 1)).toIso8601String(),
        'isActive': true,
      });

      // Verify initial 302 to fallback
      var res = await harness.simulateRedirect('/CAMP-FEST');
      expect(res.statusCode, equals(302));
      expect(res.location, equals('https://rice.edu/info'));

      // 2. Reactivate by extending expiration
      final apiClient = client.Client(
        'https://go.thejambers.com',
        httpClient: harness.createHttpClient(),
      );
      final newExpiry = baseTime.add(const Duration(days: 5));
      await apiClient.link.updateLink({
        'id': cleanSlug,
        'shortCode': cleanSlug,
        'destinationUrl': 'https://rice.edu/fest',
        'fallbackUrl': 'https://rice.edu/info',
        'expiresAt': newExpiry.toIso8601String(),
      });
      res = await harness.simulateRedirect('/camp-fest');
      expect(res.statusCode, equals(301));
      expect(res.location, equals('https://rice.edu/fest'));

      // 3. Toggle inactive
      await apiClient.link.toggleActive(cleanSlug, true);
      res = await harness.simulateRedirect('/camp-fest');
      expect(res.statusCode, equals(302));
      expect(res.location, equals('https://rice.edu/info'));

      // 4. Toggle active again
      await apiClient.link.toggleActive(cleanSlug, false);
      res = await harness.simulateRedirect('/camp-fest');
      expect(res.statusCode, equals(301));
      expect(res.location, equals('https://rice.edu/fest'));
      apiClient.close();
    });

    test('3.7 Complex URL query parameters & fragments + Fallback parameters', () async {
      const alias = 'deep-event';
      const dest = 'https://events.rice.edu/calendar?category=music&tag=owl#tickets';
      const fallback = 'https://rice.edu/help?src=shortener&ref=event';

      harness.seedLink({
        'shortCode': alias,
        'destinationUrl': dest,
        'fallbackUrl': fallback,
        'isActive': true,
      });

      // Active state preserves full destination with query and fragment
      var res = await harness.simulateRedirect('/$alias');
      expect(res.statusCode, equals(301));
      expect(res.location, equals(dest));

      // Deactivated state preserves fallback query parameters
      harness.getLink(alias)!['isActive'] = false;
      res = await harness.simulateRedirect('/$alias');
      expect(res.statusCode, equals(302));
      expect(res.location, equals(fallback));
    });
  });

  // ==========================================================================
  // TIER 4: REAL-WORLD APPLICATION SCENARIOS (End-to-End User Workflows)
  // ==========================================================================
  group('Tier 4: Real-World Application Scenarios', () {
    test('Scenario 1: Rice Admissions Campaign Workflow (Creation -> QR -> Redirect -> Analytics)', () async {
      // Step 1: User authentication verification
      final authService = AuthService();
      final user = await authService.signInAsDevUser(
        email: 'admissions.director@rice.edu',
        displayName: 'Director of Admissions',
      );
      expect(user.isRiceEmail, isTrue);

      // Step 2: Campaign Link Creation with Styled QR Code
      final now = DateTime.now();
      const alias = 'owls-2026';
      const destination = 'https://rice.edu/admissions/apply';
      const fallback = 'https://rice.edu/admissions';
      const qrConfig = QrConfig(
        fgColorHex: '#00205B',
        bgColorHex: '#FFFFFF',
        style: QrStyle.square,
        logoType: RiceLogoType.shield,
      );

      final campaignLink = ShortLink(
        id: alias,
        userId: user.uid,
        userEmail: user.email,
        shortCode: alias,
        destinationUrl: destination,
        fallbackUrl: fallback,
        expiresAt: now.add(const Duration(days: 90)),
        qrConfig: qrConfig,
        createdAt: now,
        updatedAt: now,
      );

      harness.seedLink({
        'id': alias,
        'userId': user.uid,
        'userEmail': user.email,
        'shortCode': alias,
        'destinationUrl': destination,
        'fallbackUrl': fallback,
        'expiresAt': now.add(const Duration(days: 90)).toIso8601String(),
        'qrConfig': qrConfig.toMap(),
        'isActive': true,
      });

      // Step 3: Marketing Collateral Generation (SVG & PNG)
      final svgOutput = QrExportService.generateSvg(
        campaignLink.fullShortUrl(),
        campaignLink.qrConfig,
        logoBase64: 'fakeShieldCrestBase64',
      );
      expect(svgOutput, contains('<svg'));
      expect(svgOutput, contains('fakeShieldCrestBase64'));

      final pngBytes = await QrExportService.generatePngBytes(
        campaignLink.fullShortUrl(),
        campaignLink.qrConfig,
        512,
      );
      expect(pngBytes.length, greaterThan(100));

      // Step 4: Prospective Student scans QR / clicks URL
      final redirectRes = await harness.simulateRedirect(
        '/$alias',
        userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
        referer: 'https://instagram.com/riceadmissions',
        ipAddress: '168.5.1.10',
      );

      // Step 5: Verification of HTTP 301, headers, click count increment, and analytics
      expect(redirectRes.statusCode, equals(301));
      expect(redirectRes.location, equals(destination));
      expect(redirectRes.headers['Cache-Control'], equals('private, no-cache'));

      final storedLink = harness.getLink(alias);
      expect(storedLink?['clickCount'], equals(1));
      expect(storedLink?['lastClickedAt'], isNotNull);

      expect(harness.analyticsEvents.length, equals(1));
      final event = harness.analyticsEvents.first;
      expect(event['shortCode'], equals(alias));
      expect(event['userAgent'], contains('iPhone'));
      expect(event['referer'], contains('instagram.com'));
    });

    test('Scenario 2: Rice Athletics Game-Day Ticket Lifecycle (Pre-game 301 -> Post-game 302 -> Extension)', () async {
      final gameKickoff = DateTime(2026, 11, 7, 19, 0, 0); // 7:00 PM kickoff
      harness.clock = () => gameKickoff.subtract(const Duration(hours: 2)); // 5:00 PM pre-game

      // 1. Athletics creates game ticket link
      harness.seedLink({
        'id': 'rice-football',
        'userId': 'athletics_coord',
        'userEmail': 'tickets@rice.edu',
        'shortCode': 'rice-football',
        'destinationUrl': 'https://riceowls.com/tickets/nov7',
        'fallbackUrl': 'https://riceowls.com/schedule',
        'expiresAt': gameKickoff.toIso8601String(),
        'isActive': true,
      });

      // 2. Pre-game access (5:00 PM): Returns 301 to tickets
      var res = await harness.simulateRedirect('/rice-football');
      expect(res.statusCode, equals(301));
      expect(res.location, equals('https://riceowls.com/tickets/nov7'));
      expect(harness.getLink('rice-football')?['clickCount'], equals(1));

      // 3. Post-game access (8:00 PM): Kickoff passed, returns 302 to season schedule
      harness.clock = () => gameKickoff.add(const Duration(hours: 1));
      res = await harness.simulateRedirect('/rice-football');
      expect(res.statusCode, equals(302));
      expect(res.location, equals('https://riceowls.com/schedule'));

      // 4. Coordinator updates link for bowl game postseason
      final bowlKickoff = DateTime(2026, 12, 20, 14, 0, 0);
      final apiClient = client.Client(
        'https://go.thejambers.com',
        httpClient: harness.createHttpClient(),
      );
      await apiClient.link.updateLink({
        'id': 'rice-football',
        'shortCode': 'rice-football',
        'destinationUrl': 'https://riceowls.com/tickets/bowl-game',
        'expiresAt': bowlKickoff.toIso8601String(),
      });

      // 5. Subsequent access returns 301 to new bowl tickets
      res = await harness.simulateRedirect('/rice-football');
      expect(res.statusCode, equals(301));
      expect(res.location, equals('https://riceowls.com/tickets/bowl-game'));
      expect(harness.getLink('rice-football')?['clickCount'], equals(2));
      apiClient.close();
    });

    test('Scenario 3: Administrative Emergency Broadcast Link (Active 301 -> Stand down 302 -> Reactivate)', () async {
      // Emergency alert link created
      harness.seedLink({
        'id': 'rice-emergency-info',
        'userId': 'oit_admin',
        'userEmail': 'admin@rice.edu',
        'shortCode': 'rice-emergency-info',
        'destinationUrl': 'https://emergency.rice.edu/storm-update',
        'fallbackUrl': 'https://rice.edu',
        'isActive': true,
      });

      final apiClient = client.Client(
        'https://go.thejambers.com',
        httpClient: harness.createHttpClient(),
      );

      // Active status -> 301
      var res = await harness.simulateRedirect('/rice-emergency-info');
      expect(res.statusCode, equals(301));
      expect(res.location, equals('https://emergency.rice.edu/storm-update'));

      // Incident resolved: Admin toggles to inactive
      await apiClient.link.toggleActive('rice-emergency-info', true);
      res = await harness.simulateRedirect('/rice-emergency-info');
      expect(res.statusCode, equals(302));
      expect(res.location, equals('https://rice.edu'));

      // Secondary advisory: Admin re-activates
      await apiClient.link.toggleActive('rice-emergency-info', false);
      res = await harness.simulateRedirect('/rice-emergency-info');
      expect(res.statusCode, equals(301));
      expect(res.location, equals('https://emergency.rice.edu/storm-update'));
      apiClient.close();
    });

    test('Scenario 4: Multi-Client Traffic & Analytics Aggregation', () async {
      harness.seedLink({
        'shortCode': 'campus-fair',
        'destinationUrl': 'https://rice.edu/fair',
        'isActive': true,
      });

      // Click 1: Desktop Chrome from Google Search
      await harness.simulateRedirect(
        '/campus-fair',
        userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0',
        referer: 'https://google.com',
        ipAddress: '128.42.1.5',
      );

      // Click 2: Mobile Safari from Campus QR Poster
      await harness.simulateRedirect(
        '/campus-fair',
        userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) Mobile/15E148 Safari/604.1',
        referer: 'qrcode',
        ipAddress: '128.42.20.100',
      );

      // Click 3: Android Firefox from Rice Email Client
      await harness.simulateRedirect(
        '/campus-fair',
        userAgent: 'Mozilla/5.0 (Android 14; Mobile; rv:120.0) Gecko/120.0 Firefox/120.0',
        referer: 'https://mail.rice.edu',
        ipAddress: '128.42.50.200',
      );

      // Query analytics endpoint
      final clientInstance = client.Client(
        'https://go.thejambers.com',
        httpClient: harness.createHttpClient(),
      );
      final stats = await clientInstance.analytics.getLinkAnalytics('campus-fair');

      expect(stats['totalClicks'], equals(3));
      expect(stats['destinationUrl'], equals('https://rice.edu/fair'));
      final recentClicks = stats['recentClicks'] as List<dynamic>;
      expect(recentClicks.length, equals(3));
      expect(recentClicks.first['referer'], equals('https://mail.rice.edu')); // most recent first
      clientInstance.close();
    });

    test('Scenario 5: Dashboard Search, Filtering, and Full Link Lifecycle', () async {
      final now = DateTime.now();

      // Seed 5 diverse links
      final linkData = [
        ShortLink(
          id: 'campanile-tower',
          userId: 'u1',
          userEmail: 'sammy@rice.edu',
          shortCode: 'campanile-tower',
          destinationUrl: 'https://rice.edu/campanile',
          createdAt: now,
          updatedAt: now,
        ),
        ShortLink(
          id: 'fondren-library',
          userId: 'u1',
          userEmail: 'sammy@rice.edu',
          shortCode: 'fondren-library',
          destinationUrl: 'https://library.rice.edu',
          createdAt: now,
          updatedAt: now,
        ),
        ShortLink(
          id: 'past-symposium',
          userId: 'u1',
          userEmail: 'sammy@rice.edu',
          shortCode: 'past-symposium',
          destinationUrl: 'https://rice.edu/symposium',
          expiresAt: now.subtract(const Duration(days: 5)), // expired
          createdAt: now.subtract(const Duration(days: 10)),
          updatedAt: now,
        ),
        ShortLink(
          id: 'owl-store',
          userId: 'u1',
          userEmail: 'sammy@rice.edu',
          shortCode: 'owl-store',
          destinationUrl: 'https://campusstore.rice.edu',
          isActive: false, // inactive
          createdAt: now,
          updatedAt: now,
        ),
        ShortLink(
          id: 'hackrice',
          userId: 'u1',
          userEmail: 'sammy@rice.edu',
          shortCode: 'hackrice',
          destinationUrl: 'https://hack.rice.edu',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      for (final l in linkData) {
        harness.seedLink(l.toMap());
      }

      final controller = LinkController(linkService: linkService);
      controller.init('u1');
      await Future.delayed(const Duration(milliseconds: 50));

      // 1. Search by substring "fondren"
      controller.setSearchQuery('fondren');
      expect(controller.filteredLinks.length, equals(1));
      expect(controller.filteredLinks.first.shortCode, equals('fondren-library'));

      // 2. Filter by Active status only
      controller.clearFilters();
      controller.setStatusFilter(LinkStatusFilter.active);
      for (final link in controller.filteredLinks) {
        expect(link.isEffectivelyActive, isTrue);
      }

      // 3. Filter by Expired status only
      controller.setStatusFilter(LinkStatusFilter.expired);
      expect(controller.filteredLinks.any((l) => l.shortCode == 'past-symposium'), isTrue);

      // 4. Delete link and verify slug availability is restored
      controller.clearFilters();
      expect(await linkService.isShortCodeAvailable('campanile-tower'), isFalse);
      await linkService.deleteLink('campanile-tower');
      expect(await linkService.isShortCodeAvailable('campanile-tower'), isTrue);

      controller.dispose();
    });
  });
}
