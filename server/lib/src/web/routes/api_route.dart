import 'dart:convert';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../../endpoints/link_endpoint.dart';
import '../../endpoints/analytics_endpoint.dart';

/// REST API Route handling frontend RPC requests under /api/*
class ApiRoute extends Route {
  final LinkEndpoint _linkEndpoint = LinkEndpoint();
  final AnalyticsEndpoint _analyticsEndpoint = AnalyticsEndpoint();

  @override
  Future<bool> handleCall(Session session, HttpRequest request) async {
    // 1. Always apply CORS headers for web compatibility
    _applyCorsHeaders(request.response);

    // 2. Handle HTTP OPTIONS pre-flight
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return true;
    }

    final segments = request.uri.pathSegments;
    // Expected structure: ['api', 'link'|'analytics', action]
    if (segments.length < 3 || segments[0] != 'api') {
      return false;
    }

    final category = segments[1];
    final action = segments[2];

    request.response.headers.contentType = ContentType.json;

    try {
      if (category == 'link') {
        return await _handleLinkAction(session, request, action);
      } else if (category == 'analytics') {
        return await _handleAnalyticsAction(session, request, action);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(jsonEncode({'error': 'Unknown API category: $category'}));
        await request.response.close();
        return true;
      }
    } catch (e, stack) {
      session.log('API Error in $category/$action: $e\n$stack', level: LogLevel.error);
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
      return true;
    }
  }

  Future<bool> _handleLinkAction(Session session, HttpRequest request, String action) async {
    switch (action) {
      case 'isShortCodeAvailable':
        final code = request.uri.queryParameters['code'] ?? '';
        final excludeLinkId = request.uri.queryParameters['excludeLinkId'];
        final available = await _linkEndpoint.isShortCodeAvailable(
          session,
          code,
          excludeLinkId: excludeLinkId,
        );
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({'available': available}));
        await request.response.close();
        return true;

      case 'getUserLinks':
        final userId = request.uri.queryParameters['userId'] ?? '';
        final links = await _linkEndpoint.getUserLinks(session, userId);
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode(links));
        await request.response.close();
        return true;

      case 'createLink':
        final bodyString = await utf8.decodeStream(request);
        final data = jsonDecode(bodyString) as Map<String, dynamic>;
        final created = await _linkEndpoint.createLink(session, data);
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode(created));
        await request.response.close();
        return true;

      case 'updateLink':
        final bodyString = await utf8.decodeStream(request);
        final data = jsonDecode(bodyString) as Map<String, dynamic>;
        final updated = await _linkEndpoint.updateLink(session, data);
        request.response.statusCode = updated ? HttpStatus.ok : HttpStatus.badRequest;
        request.response.write(jsonEncode({'success': updated}));
        await request.response.close();
        return true;

      case 'toggleActive':
        final bodyString = await utf8.decodeStream(request);
        final data = jsonDecode(bodyString) as Map<String, dynamic>;
        final linkId = data['linkId'] as String;
        final currentStatus = data['currentStatus'] as bool? ?? true;
        final toggled = await _linkEndpoint.toggleActive(session, linkId, currentStatus);
        request.response.statusCode = toggled ? HttpStatus.ok : HttpStatus.badRequest;
        request.response.write(jsonEncode({'success': toggled}));
        await request.response.close();
        return true;

      case 'deleteLink':
        final bodyString = await utf8.decodeStream(request);
        final data = jsonDecode(bodyString) as Map<String, dynamic>;
        final linkId = data['linkId'] as String;
        final deleted = await _linkEndpoint.deleteLink(session, linkId);
        request.response.statusCode = deleted ? HttpStatus.ok : HttpStatus.badRequest;
        request.response.write(jsonEncode({'success': deleted}));
        await request.response.close();
        return true;

      default:
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(jsonEncode({'error': 'Unknown link action: $action'}));
        await request.response.close();
        return true;
    }
  }

  Future<bool> _handleAnalyticsAction(Session session, HttpRequest request, String action) async {
    switch (action) {
      case 'getLinkAnalytics':
        final shortCode = request.uri.queryParameters['shortCode'] ?? '';
        final stats = await _analyticsEndpoint.getLinkAnalytics(session, shortCode);
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode(stats));
        await request.response.close();
        return true;

      default:
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(jsonEncode({'error': 'Unknown analytics action: $action'}));
        await request.response.close();
        return true;
    }
  }

  void _applyCorsHeaders(HttpResponse response) {
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    response.headers.set('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  }
}
