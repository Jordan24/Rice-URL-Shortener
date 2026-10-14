import '../models/short_link.dart';

/// Abstract service interface for link management operations.
/// Decouples UI controllers from the specific backend provider
/// (AWS Serverpod vs. Firebase Firestore).
abstract class LinkService {
  /// Checks whether a short code is available and valid
  Future<bool> isShortCodeAvailable(String code, {String? excludeLinkId});

  /// Streams links owned by a specific user with real-time updates
  Stream<List<ShortLink>> streamUserLinks(String userId);

  /// Creates a new short link
  Future<ShortLink> createLink(ShortLink link);

  /// Updates an existing short link
  Future<void> updateLink(ShortLink link);

  /// Toggles link active state
  Future<void> toggleLinkActive(String linkId, bool currentStatus);

  /// Deletes a short link
  Future<void> deleteLink(String linkId);

  /// Cleans up resources, streams, and connections
  void dispose();
}
