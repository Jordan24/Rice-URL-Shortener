import 'dart:convert';
import 'package:serverpod/serverpod.dart';

/// RPC Endpoint handling link creation, retrieval, updates, and availability
class LinkEndpoint extends Endpoint {
  static const Set<String> reservedRoutes = {
    'app', 'api', 'login', 'auth', 'dashboard', 'static', 'r', 'admin',
    'assets', 'favicon', 'favicon.ico', 'manifest', 'null', 'undefined',
    'help', 'about', 'settings', 'health', 'metrics', 'flutter', 'canvaskit',
    'icons', 'version', 'robots', 'robots.txt', 'sitemap', 'sitemap.xml',
  };

  /// Check whether a shortcode is valid and available
  Future<bool> isShortCodeAvailable(
    Session session,
    String code, {
    String? excludeLinkId,
  }) async {
    final lowerCode = code.trim().toLowerCase();
    if (reservedRoutes.contains(lowerCode) || lowerCode.length < 3) {
      return false;
    }

    String sql = 'SELECT id FROM short_link WHERE LOWER(short_code) = \$1';
    List<dynamic> params = [lowerCode];

    if (excludeLinkId != null && excludeLinkId.isNotEmpty) {
      sql += ' AND link_id != \$2';
      params.add(excludeLinkId);
    }
    sql += ' LIMIT 1;';

    final result = await session.db.unsafeQuery(sql, parameters: QueryParameters.positional(params));
    return result.isEmpty;
  }

  /// Retrieve all short links created by a given user
  Future<List<Map<String, dynamic>>> getUserLinks(Session session, String userId) async {
    final sql = '''
      SELECT link_id, user_id, user_email, short_code, destination_url, fallback_url,
             expires_at, is_active, click_count, last_clicked_at, created_at, updated_at,
             qr_config_json
      FROM short_link
      WHERE user_id = \$1
      ORDER BY created_at DESC;
    ''';

    final result = await session.db.unsafeQuery(sql, parameters: QueryParameters.positional([userId]));
    return result.map((row) => _rowToMap(row)).toList();
  }

  /// Create a new short link
  Future<Map<String, dynamic>> createLink(
    Session session,
    Map<String, dynamic> linkData,
  ) async {
    final code = (linkData['shortCode'] as String).trim().toLowerCase();
    final available = await isShortCodeAvailable(session, code);
    if (!available) {
      throw FormatException('Short code "$code" is unavailable or reserved.');
    }

    final linkId = (linkData['id'] as String?)?.isNotEmpty == true
        ? linkData['id'] as String
        : code;
    final userId = linkData['userId'] as String;
    final userEmail = linkData['userEmail'] as String;
    final destination = (linkData['destinationUrl'] as String).trim();
    if (!destination.startsWith('http://') && !destination.startsWith('https://')) {
      throw const FormatException('Destination URL must begin with http:// or https://');
    }
    final rawFallback = (linkData['fallbackUrl'] as String?)?.trim() ?? 'https://rice.edu';
    final fallback = (rawFallback.startsWith('http://') || rawFallback.startsWith('https://'))
        ? rawFallback
        : 'https://rice.edu';
    final expiresAt = linkData['expiresAt'] != null ? DateTime.parse(linkData['expiresAt']) : null;
    final qrConfigJson = linkData['qrConfig'] != null ? jsonEncode(linkData['qrConfig']) : null;

    final sql = '''
      INSERT INTO short_link (
        link_id, user_id, user_email, short_code, destination_url, fallback_url,
        expires_at, is_active, click_count, created_at, updated_at, qr_config_json
      ) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, TRUE, 0, NOW(), NOW(), \$8)
      RETURNING link_id, user_id, user_email, short_code, destination_url, fallback_url,
                expires_at, is_active, click_count, last_clicked_at, created_at, updated_at,
                qr_config_json;
    ''';

    final result = await session.db.unsafeQuery(
      sql,
      parameters: QueryParameters.positional([
        linkId, userId, userEmail, code, destination, fallback, expiresAt, qrConfigJson,
      ]),
    );

    return _rowToMap(result.first);
  }

  /// Update an existing short link
  Future<bool> updateLink(Session session, Map<String, dynamic> linkData) async {
    final linkId = linkData['id'] as String;
    final code = (linkData['shortCode'] as String).trim().toLowerCase();
    final available = await isShortCodeAvailable(session, code, excludeLinkId: linkId);
    if (!available) {
      throw FormatException('Short code "$code" is already taken.');
    }

    final destination = (linkData['destinationUrl'] as String).trim();
    if (!destination.startsWith('http://') && !destination.startsWith('https://')) {
      throw const FormatException('Destination URL must begin with http:// or https://');
    }
    final rawFallback = (linkData['fallbackUrl'] as String?)?.trim() ?? 'https://rice.edu';
    final fallback = (rawFallback.startsWith('http://') || rawFallback.startsWith('https://'))
        ? rawFallback
        : 'https://rice.edu';
    final expiresAt = linkData['expiresAt'] != null ? DateTime.parse(linkData['expiresAt']) : null;
    final qrConfigJson = linkData['qrConfig'] != null ? jsonEncode(linkData['qrConfig']) : null;

    final sql = '''
      UPDATE short_link SET
        short_code = \$1,
        destination_url = \$2,
        fallback_url = \$3,
        expires_at = \$4,
        qr_config_json = \$5,
        updated_at = NOW()
      WHERE link_id = \$6;
    ''';

    final rowsAffected = await session.db.unsafeExecute(
      sql,
      parameters: QueryParameters.positional([
        code, destination, fallback, expiresAt, qrConfigJson, linkId,
      ]),
    );

    return rowsAffected > 0;
  }

  /// Toggle link active state
  Future<bool> toggleActive(Session session, String linkId, bool currentStatus) async {
    final sql = 'UPDATE short_link SET is_active = \$1, updated_at = NOW() WHERE link_id = \$2;';
    final rowsAffected = await session.db.unsafeExecute(
      sql,
      parameters: QueryParameters.positional([!currentStatus, linkId]),
    );
    return rowsAffected > 0;
  }

  /// Delete a link
  Future<bool> deleteLink(Session session, String linkId) async {
    final sql = 'DELETE FROM short_link WHERE link_id = \$1;';
    final rowsAffected = await session.db.unsafeExecute(
      sql,
      parameters: QueryParameters.positional([linkId]),
    );
    return rowsAffected > 0;
  }

  Map<String, dynamic> _rowToMap(List<dynamic> row) {
    return {
      'id': row[0] as String,
      'userId': row[1] as String,
      'userEmail': row[2] as String,
      'shortCode': row[3] as String,
      'destinationUrl': row[4] as String,
      'fallbackUrl': row[5] as String?,
      'expiresAt': (row[6] as DateTime?)?.toIso8601String(),
      'isActive': row[7] as bool,
      'clickCount': (row[8] as num).toInt(),
      'lastClickedAt': (row[9] as DateTime?)?.toIso8601String(),
      'createdAt': (row[10] as DateTime).toIso8601String(),
      'updatedAt': (row[11] as DateTime).toIso8601String(),
      'qrConfig': row[12] != null
          ? (row[12] is Map ? row[12] : (row[12] is String ? jsonDecode(row[12] as String) : row[12]))
          : null,
    };
  }
}

