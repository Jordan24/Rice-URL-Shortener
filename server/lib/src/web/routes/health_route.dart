import 'dart:io';
import 'package:serverpod/serverpod.dart';

/// Health check route for AWS ALB and Docker container healthchecks
class HealthRoute extends Route {
  @override
  Future<bool> handleCall(Session session, HttpRequest request) async {
    request.response.headers.contentType = ContentType.json;
    request.response.headers.set('X-Robots-Tag', 'noindex, nofollow, noarchive');
    request.response.statusCode = HttpStatus.ok;
    request.response.write('{"status":"healthy","service":"rice-url-shortener"}');
    await request.response.close();
    return true;
  }
}

