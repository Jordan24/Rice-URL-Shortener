import 'package:serverpod/serverpod.dart';

/// RPC Endpoint retrieving link click analytics and historical performance
class AnalyticsEndpoint extends Endpoint {
  /// Get analytics summary for a specific short link
  Future<Map<String, dynamic>> getLinkAnalytics(Session session, String shortCode) async {
    final code = shortCode.trim().toLowerCase();

    // 1. Get aggregate stats from short_link
    final linkQuery = '''
      SELECT link_id, short_code, destination_url, click_count, last_clicked_at, created_at
      FROM short_link
      WHERE LOWER(short_code) = \$1
      LIMIT 1;
    ''';
    final linkResult = await session.db.unsafeQuery(linkQuery, parameters: QueryParameters.positional([code]));
    if (linkResult.isEmpty) {
      throw FormatException('Short link "$code" not found.');
    }

    final linkRow = linkResult.first;
    final totalClicks = (linkRow[3] as num).toInt();
    final lastClickedAt = (linkRow[4] as DateTime?)?.toIso8601String();
    final createdAt = (linkRow[5] as DateTime).toIso8601String();

    // 2. Get last 20 click events
    final eventsQuery = '''
      SELECT timestamp, user_agent, referer, ip_address
      FROM link_analytics_event
      WHERE LOWER(short_code) = \$1
      ORDER BY timestamp DESC
      LIMIT 20;
    ''';
    final eventsResult = await session.db.unsafeQuery(eventsQuery, parameters: QueryParameters.positional([code]));

    final recentClicks = eventsResult.map((row) => {
      'timestamp': (row[0] as DateTime).toIso8601String(),
      'userAgent': row[1] as String?,
      'referer': row[2] as String?,
    }).toList();

    return {
      'shortCode': code,
      'destinationUrl': linkRow[2] as String,
      'totalClicks': totalClicks,
      'lastClickedAt': lastClickedAt,
      'createdAt': createdAt,
      'recentClicks': recentClicks,
    };
  }
}

