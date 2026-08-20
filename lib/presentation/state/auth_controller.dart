import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<RiceUser?>? _subscription;

  RiceUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthController({required this._authService}) {
    _currentUser = _authService.currentUser;
    _subscription = _authService.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  RiceUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithRiceGoogle();
      _currentUser = user;
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

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _authService.signOut();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
