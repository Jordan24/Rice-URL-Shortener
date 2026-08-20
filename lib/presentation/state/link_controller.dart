import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/short_link.dart';
import '../../data/services/firestore_link_service.dart';

enum LinkStatusFilter { all, active, expired }

class LinkController extends ChangeNotifier {
  final FirestoreLinkService _linkService;
  StreamSubscription<List<ShortLink>>? _linksSubscription;

  List<ShortLink> _allLinks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = "";
  LinkStatusFilter _statusFilter = LinkStatusFilter.all;

  LinkController({required this._linkService});

  List<ShortLink> get allLinks => _allLinks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  LinkStatusFilter get statusFilter => _statusFilter;

  List<ShortLink> get filteredLinks {
    return _allLinks.where((link) {
      // Status filter
      if (_statusFilter == LinkStatusFilter.active && !link.isEffectivelyActive) {
        return false;
      }
      if (_statusFilter == LinkStatusFilter.expired && !link.isExpired) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchCode = link.shortCode.toLowerCase().contains(query);
        final matchDest = link.destinationUrl.toLowerCase().contains(query);
        final matchFallback = link.fallbackUrl.toLowerCase().contains(query);
        return matchCode || matchDest || matchFallback;
      }

      return true;
    }).toList();
  }

  void init(String userId) {
    _isLoading = true;
    notifyListeners();

    _linksSubscription?.cancel();
    _linksSubscription = _linkService.streamUserLinks(userId).listen(
      (links) {
        _allLinks = links;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setStatusFilter(LinkStatusFilter filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  Future<bool> createLink(ShortLink link) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _linkService.createLink(link);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLink(ShortLink link) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _linkService.updateLink(link);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleActive(ShortLink link) async {
    try {
      await _linkService.toggleLinkActive(link.id, link.isActive);
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
    }
  }

  Future<void> deleteLink(String linkId) async {
    try {
      await _linkService.deleteLink(linkId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _linksSubscription?.cancel();
    super.dispose();
  }
}
