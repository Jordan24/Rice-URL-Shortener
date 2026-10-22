import 'dart:io';
import 'package:serverpod/serverpod.dart';

/// High-performance HTTP redirect route for Rice shortened URLs
class RedirectRoute extends Route {
  static const String defaultFallbackUrl = 'https://rice.edu';
  static const Set<String> reservedPaths = {
    'app', 'api', 'login', 'auth', 'dashboard', 'static', 'r', 'admin',
    'assets', 'favicon', 'favicon.ico', 'manifest', 'null', 'undefined',
    'help', 'about', 'settings', 'health', 'metrics', 'flutter', 'canvaskit',
    'icons', 'version', 'robots', 'sitemap', 'sitemap.xml',
  };

  @override
  Future<bool> handleCall(Session session, HttpRequest request) async {
    request.response.headers.set('X-Robots-Tag', 'noindex, nofollow, noarchive');

    final segments = request.uri.pathSegments;
    if (segments.isEmpty) {
      return false;
    }

    final code = segments.first.trim().toLowerCase();
    if (code == 'robots.txt') {
      request.response.headers.contentType = ContentType.text;
      request.response.statusCode = HttpStatus.ok;
      request.response.write('User-agent: *\nDisallow: /api/\nAllow: /\n');
      await request.response.close();
      return true;
    }

    if (reservedPaths.contains(code)) {
      return false; // Let subsequent routers or static handlers process
    }

    try {
      // Query PostgreSQL database using raw session connection
      final query = 'SELECT link_id, destination_url, fallback_url, expires_at, is_active FROM short_link WHERE LOWER(short_code) = \$1 LIMIT 1;';
      final result = await session.db.unsafeQuery(query, parameters: QueryParameters.positional([code]));

      if (result.isEmpty) {
        request.response.redirect(Uri.parse(defaultFallbackUrl), status: HttpStatus.movedTemporarily);
        await request.response.close();
        return true;
      }

      final row = result.first;
      final linkId = row[0] as String;
      final destinationUrl = row[1] as String;
      final fallbackUrl = (row[2] as String?) ?? defaultFallbackUrl;
      final expiresAt = row[3] as DateTime?;
      final isActive = (row[4] as bool?) ?? true;

      // Check active state
      if (!isActive) {
        request.response.redirect(Uri.parse(fallbackUrl), status: HttpStatus.movedTemporarily);
        await request.response.close();
        return true;
      }

      // Check expiration
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        request.response.redirect(Uri.parse(fallbackUrl), status: HttpStatus.movedTemporarily);
        await request.response.close();
        return true;
      }

      // Async fire-and-forget click analytics update
      _recordClickAsync(session, linkId, code, request);

      // Perform fast HTTP 301 Permanent Redirect
      request.response.headers.set('Cache-Control', 'private, no-cache');
      request.response.redirect(Uri.parse(destinationUrl), status: HttpStatus.movedPermanently);
      await request.response.close();
      return true;
    } catch (e) {
      session.log('Redirect error: $e', level: LogLevel.error);
      request.response.redirect(Uri.parse(defaultFallbackUrl), status: HttpStatus.movedTemporarily);
      await request.response.close();
      return true;
    }
  }

  void _recordClickAsync(Session session, String linkId, String code, HttpRequest request) {
    // Atomically increment click count and insert analytics log
    final updateSql = 'UPDATE short_link SET click_count = click_count + 1, last_clicked_at = NOW() WHERE link_id = \$1;';
    session.db.unsafeExecute(updateSql, parameters: QueryParameters.positional([linkId])).catchError((err) {
      session.log('Failed to increment click count: $err', level: LogLevel.warning);
      return 0;
    });

    final insertLogSql = 'INSERT INTO link_analytics_event (link_id, short_code, timestamp, user_agent, referer, ip_address) VALUES (\$1, \$2, NOW(), \$3, \$4, \$5);';
    final userAgent = request.headers.value(HttpHeaders.userAgentHeader);
    final referer = request.headers.value(HttpHeaders.refererHeader);
    final ipAddress = request.connectionInfo?.remoteAddress.address;

    session.db.unsafeExecute(
      insertLogSql,
      parameters: QueryParameters.positional([linkId, code, userAgent, referer, ipAddress]),
    ).catchError((err) {
      session.log('Failed to insert analytics event: $err', level: LogLevel.warning);
      return 0;
    });
  }
}

