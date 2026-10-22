import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService authService;
  StreamSubscription<RiceUser?>? _subscription;

  RiceUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthController({required this.authService}) {
    _currentUser = authService.currentUser;
    _subscription = authService.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  AuthService get _authService => authService;

  RiceUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDevMode => _authService.isDevMode;

  String _cleanError(Object error) {
    var msg = error.toString();
    if (msg.startsWith("Exception: ")) {
      msg = msg.substring(11);
    } else if (msg.startsWith("FormatException: ")) {
      msg = msg.substring(17);
    }
    return msg;
  }

  /// Sign In with Rice Email and Password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithPassword(
        email: email,
        password: password,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  /// Sign Up with Email, Password, and Display Name
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  /// Confirm Sign Up with Verification Code (OTP)
  Future<bool> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.confirmSignUp(
        email: email,
        confirmationCode: confirmationCode,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  /// Resend Verification Code
  Future<bool> resendConfirmationCode({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resendConfirmationCode(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  /// Request Password Reset Code
  Future<bool> forgotPassword({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  /// Confirm Password Reset
  Future<bool> confirmForgotPassword({
    required String email,
    required String confirmationCode,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.confirmForgotPassword(
        email: email,
        confirmationCode: confirmationCode,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  /// Local Dev Mode bypass (strictly disabled in release builds)
  Future<bool> signInAsDev({
    String email = "sammy.owl@rice.edu",
    String displayName = "Sammy the Owl",
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInAsDevUser(
        email: email,
        displayName: displayName,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _cleanError(e);
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
