import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/short_link.dart';
import '../models/qr_config.dart';
import 'link_service.dart';
import 'package:rice_url_shortener_client/rice_url_shortener_client.dart' as client;

/// Link Service connecting the Flutter web frontend to the Serverpod backend
class ServerpodLinkService implements LinkService {
  final String backendUrl;
  final client.Client _client;
  final StreamController<List<ShortLink>> _linksStreamController =
      StreamController<List<ShortLink>>.broadcast();
  final List<ShortLink> _cachedLinks = [];

  ServerpodLinkService({
    this.backendUrl = 'http://localhost:8080',
    http.Client? httpClient,
  }) : _client = client.Client(backendUrl, httpClient: httpClient) {
    _initDefaultCache();
  }

  void _initDefaultCache() {
    _cachedLinks.addAll([
      ShortLink(
        id: 'campanile',
        userId: 'rice_demo_uid_1912',
        userEmail: 'sammy.owl@rice.edu',
        shortCode: 'campanile',
        destinationUrl: 'https://rice.edu/about',
        fallbackUrl: 'https://rice.edu',
        isActive: true,
        clickCount: 142,
        lastClickedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ShortLink(
        id: 'fest26',
        userId: 'rice_demo_uid_1912',
        userEmail: 'sammy.owl@rice.edu',
        shortCode: 'fest26',
        destinationUrl: 'https://events.rice.edu',
        fallbackUrl: 'https://rice.edu',
        expiresAt: DateTime.now().add(const Duration(days: 5)),
        isActive: true,
        clickCount: 38,
        lastClickedAt: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ]);
  }

  /// Check if a short code is available
  @override
  Future<bool> isShortCodeAvailable(String code, {String? excludeLinkId}) async {
    final lowerCode = code.trim().toLowerCase();
    if (AppConstants.reservedRoutes.contains(lowerCode) || lowerCode.length < 3) {
      return false;
    }

    try {
      return await _client.link.isShortCodeAvailable(lowerCode, excludeLinkId: excludeLinkId);
    } catch (_) {
      // Offline fallback: check local cache
      final match = _cachedLinks.where((l) => l.shortCode == lowerCode && l.id != excludeLinkId);
      return match.isEmpty;
    }
  }

  /// Stream user links with real-time updates and polling fallback
  @override
  Stream<List<ShortLink>> streamUserLinks(String userId) {
    Future.microtask(() => _linksStreamController.add(List.from(_cachedLinks)));
    _refreshLinks(userId);
    return _linksStreamController.stream;
  }

  Future<void> _refreshLinks(String userId) async {
    try {
      final records = await _client.link.getUserLinks(userId);
      _cachedLinks.clear();
      for (final r in records) {
        _cachedLinks.add(_recordToShortLink(r));
      }
      _linksStreamController.add(List.from(_cachedLinks));
    } catch (_) {
      // Emit cached links if offline
      _linksStreamController.add(List.from(_cachedLinks));
    }
  }

  /// Create a new short link
  @override
  Future<ShortLink> createLink(ShortLink link) async {
    final code = link.shortCode.trim().toLowerCase();
    final available = await isShortCodeAvailable(code);
    if (!available) {
      throw Exception('The short code "$code" is already taken or reserved.');
    }

    try {
      final payload = link.toJsonMap();
      payload['shortCode'] = code;
      final createdRecord = await _client.link.createLink(payload);
      final newLink = _recordToShortLink(createdRecord);
      _cachedLinks.insert(0, newLink);
      _linksStreamController.add(List.from(_cachedLinks));
      return newLink;
    } catch (e) {
      // Local optimistic fallback
      final fallbackLink = link.copyWith(id: code, shortCode: code);
      _cachedLinks.insert(0, fallbackLink);
      _linksStreamController.add(List.from(_cachedLinks));
      return fallbackLink;
    }
  }

  /// Update an existing short link
  @override
  Future<void> updateLink(ShortLink link) async {
    final code = link.shortCode.trim().toLowerCase();
    final linkId = link.id.isNotEmpty ? link.id : code;

    try {
      final payload = link.toJsonMap();
      payload['id'] = linkId;
      payload['shortCode'] = code;
      await _client.link.updateLink(payload);
    } catch (_) {}

    final index = _cachedLinks.indexWhere((l) => l.id == linkId);
    if (index != -1) {
      _cachedLinks[index] = link.copyWith(id: linkId, shortCode: code, updatedAt: DateTime.now());
      _linksStreamController.add(List.from(_cachedLinks));
    }
  }

  /// Toggle link active status
  @override
  Future<void> toggleLinkActive(String linkId, bool currentStatus) async {
    try {
      await _client.link.toggleActive(linkId, currentStatus);
    } catch (_) {}

    final index = _cachedLinks.indexWhere((l) => l.id == linkId);
    if (index != -1) {
      _cachedLinks[index] = _cachedLinks[index].copyWith(
        isActive: !currentStatus,
        updatedAt: DateTime.now(),
      );
      _linksStreamController.add(List.from(_cachedLinks));
    }
  }

  /// Delete a link
  @override
  Future<void> deleteLink(String linkId) async {
    try {
      await _client.link.deleteLink(linkId);
    } catch (_) {}

    _cachedLinks.removeWhere((l) => l.id == linkId);
    _linksStreamController.add(List.from(_cachedLinks));
  }

  ShortLink _recordToShortLink(client.ShortLinkRecord r) {
    QrConfig qrConfig = const QrConfig();
    if (r.qrConfigJson != null && r.qrConfigJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(r.qrConfigJson!);
        if (decoded is Map<String, dynamic>) {
          qrConfig = QrConfig.fromMap(decoded);
        }
      } catch (_) {}
    }

    return ShortLink(
      id: r.linkId,
      userId: r.userId,
      userEmail: r.userEmail,
      shortCode: r.shortCode,
      destinationUrl: r.destinationUrl,
      fallbackUrl: r.fallbackUrl,
      expiresAt: r.expiresAt,
      isActive: r.isActive,
      clickCount: r.clickCount,
      lastClickedAt: r.lastClickedAt,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      qrConfig: qrConfig,
    );
  }

  @override
  void dispose() {
    _linksStreamController.close();
    _client.close();
  }
}
