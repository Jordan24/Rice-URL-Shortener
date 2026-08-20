import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/short_link.dart';

class FirestoreLinkService {
  final FirebaseFirestore? _firestore;
  final StreamController<List<ShortLink>> _mockLinksController = StreamController<List<ShortLink>>.broadcast();
  final List<ShortLink> _mockLinks = [];

  FirestoreLinkService({this._firestore}) {
    _initMockData();
  }

  void _initMockData() {
    _mockLinks.addAll([
      ShortLink(
        id: "campanile",
        userId: "rice_demo_uid_1912",
        userEmail: "sammy.owl@rice.edu",
        shortCode: "campanile",
        destinationUrl: "https://rice.edu/about",
        fallbackUrl: "https://rice.edu",
        isActive: true,
        clickCount: 142,
        lastClickedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ShortLink(
        id: "fest26",
        userId: "rice_demo_uid_1912",
        userEmail: "sammy.owl@rice.edu",
        shortCode: "fest26",
        destinationUrl: "https://events.rice.edu",
        fallbackUrl: "https://rice.edu",
        expiresAt: DateTime.now().add(const Duration(days: 5)),
        isActive: true,
        clickCount: 38,
        lastClickedAt: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ]);
  }

  /// Checks if a shortcode is already in use
  Future<bool> isShortCodeAvailable(String code, {String? excludeLinkId}) async {
    final lowerCode = code.trim().toLowerCase();
    if (AppConstants.reservedRoutes.contains(lowerCode)) {
      return false;
    }

    if (_firestore != null) {
      final doc = await _firestore.collection("links").doc(lowerCode).get();
      if (!doc.exists) return true;
      if (excludeLinkId != null && doc.id == excludeLinkId) {
        return true;
      }
      return false;
    } else {
      final match = _mockLinks.where((l) => l.shortCode == lowerCode && l.id != excludeLinkId);
      return match.isEmpty;
    }
  }

  /// Stream real-time updates for a given user
  Stream<List<ShortLink>> streamUserLinks(String userId) {
    if (_firestore != null) {
      return _firestore
          .collection("links")
          .where("userId", isEqualTo: userId)
          .orderBy("createdAt", descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => ShortLink.fromFirestore(doc)).toList());
    } else {
      Future.microtask(() => _mockLinksController.add(List.from(_mockLinks)));
      return _mockLinksController.stream;
    }
  }

  /// Create a new short link with deterministic document ID to guarantee uniqueness
  Future<ShortLink> createLink(ShortLink link) async {
    final code = link.shortCode.trim().toLowerCase();
    final available = await isShortCodeAvailable(code);
    if (!available) {
      throw Exception('The short code "$code" is already taken or reserved.');
    }

    final finalLink = link.copyWith(id: code, shortCode: code);

    if (_firestore != null) {
      final docRef = _firestore.collection("links").doc(code);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        throw Exception('The short code "$code" is already taken.');
      }
      await docRef.set(finalLink.toMap());
      return finalLink;
    } else {
      _mockLinks.insert(0, finalLink);
      _mockLinksController.add(List.from(_mockLinks));
      return finalLink;
    }
  }

  /// Update an existing short link
  Future<void> updateLink(ShortLink link) async {
    final code = link.shortCode.trim().toLowerCase();
    final docId = link.id.isNotEmpty ? link.id : code;
    final available = await isShortCodeAvailable(code, excludeLinkId: docId);
    if (!available) {
      throw Exception('The short code "$code" is already taken.');
    }

    final updated = link.copyWith(id: docId, shortCode: code, updatedAt: DateTime.now());

    if (_firestore != null) {
      await _firestore.collection("links").doc(docId).update(updated.toMap());
    } else {
      final index = _mockLinks.indexWhere((l) => l.id == docId);
      if (index != -1) {
        _mockLinks[index] = updated;
        _mockLinksController.add(List.from(_mockLinks));
      }
    }
  }

  /// Toggle link active status
  Future<void> toggleLinkActive(String linkId, bool currentStatus) async {
    if (_firestore != null) {
      await _firestore.collection("links").doc(linkId).update({
        "isActive": !currentStatus,
        "updatedAt": Timestamp.fromDate(DateTime.now()),
      });
    } else {
      final index = _mockLinks.indexWhere((l) => l.id == linkId);
      if (index != -1) {
        _mockLinks[index] = _mockLinks[index].copyWith(
          isActive: !currentStatus,
          updatedAt: DateTime.now(),
        );
        _mockLinksController.add(List.from(_mockLinks));
      }
    }
  }

  /// Delete a link
  Future<void> deleteLink(String linkId) async {
    if (_firestore != null) {
      await _firestore.collection("links").doc(linkId).delete();
    } else {
      _mockLinks.removeWhere((l) => l.id == linkId);
      _mockLinksController.add(List.from(_mockLinks));
    }
  }

  void dispose() {
    _mockLinksController.close();
  }
}
