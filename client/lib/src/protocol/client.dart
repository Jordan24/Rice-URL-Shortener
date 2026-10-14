import 'dart:convert';
import 'package:http/http.dart' as http;
import 'short_link.dart';

/// Serverpod Client for Rice URL Shortener backend
class Client {
  final String host;
  final http.Client _httpClient;

  late final EndpointLink link;
  late final EndpointAnalytics analytics;

  Client(this.host, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client() {
    link = EndpointLink(this);
    analytics = EndpointAnalytics(this);
  }

  void close() {
    _httpClient.close();
  }
}

class EndpointLink {
  final Client _client;

  EndpointLink(this._client);

  Future<bool> isShortCodeAvailable(String code, {String? excludeLinkId}) async {
    final uri = Uri.parse('${_client.host}/api/link/isShortCodeAvailable').replace(
      queryParameters: {
        'code': code,
        if (excludeLinkId != null) 'excludeLinkId': excludeLinkId,
      },
    );
    final response = await _client._httpClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['available'] as bool? ?? false;
    }
    return false;
  }

  Future<List<ShortLinkRecord>> getUserLinks(String userId) async {
    final uri = Uri.parse('${_client.host}/api/link/getUserLinks').replace(
      queryParameters: {'userId': userId},
    );
    final response = await _client._httpClient.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((item) => ShortLinkRecord.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<ShortLinkRecord> createLink(Map<String, dynamic> linkData) async {
    final uri = Uri.parse('${_client.host}/api/link/createLink');
    final response = await _client._httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(linkData),
    );
    if (response.statusCode == 200) {
      return ShortLinkRecord.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create short link: ${response.body}');
  }

  Future<bool> updateLink(Map<String, dynamic> linkData) async {
    final uri = Uri.parse('${_client.host}/api/link/updateLink');
    final response = await _client._httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(linkData),
    );
    return response.statusCode == 200;
  }

  Future<bool> toggleActive(String linkId, bool currentStatus) async {
    final uri = Uri.parse('${_client.host}/api/link/toggleActive');
    final response = await _client._httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'linkId': linkId, 'currentStatus': currentStatus}),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteLink(String linkId) async {
    final uri = Uri.parse('${_client.host}/api/link/deleteLink');
    final response = await _client._httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'linkId': linkId}),
    );
    return response.statusCode == 200;
  }
}

class EndpointAnalytics {
  final Client _client;

  EndpointAnalytics(this._client);

  Future<Map<String, dynamic>> getLinkAnalytics(String shortCode) async {
    final uri = Uri.parse('${_client.host}/api/analytics/getLinkAnalytics').replace(
      queryParameters: {'shortCode': shortCode},
    );
    final response = await _client._httpClient.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to get analytics: ${response.body}');
  }
}

