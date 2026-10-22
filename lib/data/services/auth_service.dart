import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';

class RiceUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? accessToken;
  final String? idToken;
  final String? refreshToken;

  const RiceUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.accessToken,
    this.idToken,
    this.refreshToken,
  });

  bool get isRiceEmail {
    final clean = email.trim().toLowerCase();
    final suffix = '@${AppConstants.allowedAuthDomain}';
    return clean.endsWith(suffix) && clean.length > suffix.length;
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'accessToken': accessToken,
    'idToken': idToken,
    'refreshToken': refreshToken,
  };

  factory RiceUser.fromMap(Map<String, dynamic> map) => RiceUser(
    uid: map['uid'] as String? ?? '',
    email: map['email'] as String? ?? '',
    displayName: map['displayName'] as String? ?? '',
    photoUrl: map['photoUrl'] as String?,
    accessToken: map['accessToken'] as String?,
    idToken: map['idToken'] as String?,
    refreshToken: map['refreshToken'] as String?,
  );
}

/// Abstract session storage to enable session persistence on web and mocking in unit tests
abstract class AuthSessionStorage {
  String? read(String key);
  void write(String key, String value);
  void delete(String key);
}

/// In-memory storage for non-web environments and unit tests
class InMemoryAuthSessionStorage implements AuthSessionStorage {
  final Map<String, String> _storage = {};

  @override
  String? read(String key) => _storage[key];

  @override
  void write(String key, String value) => _storage[key] = value;

  @override
  void delete(String key) => _storage.remove(key);
}

/// Default session storage that maintains session in memory and supports persistence
class DefaultAuthSessionStorage implements AuthSessionStorage {
  static final Map<String, String> _globalMemory = {};

  @override
  String? read(String key) => _globalMemory[key];

  @override
  void write(String key, String value) => _globalMemory[key] = value;

  @override
  void delete(String key) => _globalMemory.remove(key);
}

class AuthService {
  static const String sessionKey = 'rice_auth_session';

  final String userPoolId;
  final String clientId;
  final String region;
  final http.Client _httpClient;
  final AuthSessionStorage _sessionStorage;

  final StreamController<RiceUser?> _authStateController = StreamController<RiceUser?>.broadcast();
  RiceUser? _currentUser;

  AuthService({
    this.userPoolId = const String.fromEnvironment('COGNITO_USER_POOL_ID', defaultValue: 'us-east-2_LnzgSMDN1'),
    this.clientId = const String.fromEnvironment('COGNITO_CLIENT_ID', defaultValue: '4fo9g0ld8p6i0lkojb4s828hjr'),
    this.region = const String.fromEnvironment('COGNITO_REGION', defaultValue: 'us-east-2'),
    http.Client? httpClient,
    AuthSessionStorage? sessionStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _sessionStorage = sessionStorage ?? DefaultAuthSessionStorage() {
    _restoreSession();
  }

  RiceUser? get currentUser => _currentUser;
  Stream<RiceUser?> get authStateChanges => _authStateController.stream;

  /// Dev mode is strictly restricted to local debug mode (kDebugMode).
  /// Guaranteed false in release builds (flutter build web --release).
  bool get isDevMode => kDebugMode;

  String get endpoint => 'https://cognito-idp.$region.amazonaws.com/';

  Map<String, String> _headers(String target) => {
    'Content-Type': 'application/x-amz-json-1.1',
    'X-Amz-Target': 'AWSCognitoIdentityProviderService.$target',
  };

  /// Strict client-side validation for @rice.edu email domain
  static void validateRiceEmail(String email) {
    final clean = email.trim().toLowerCase();
    final suffix = '@${AppConstants.allowedAuthDomain}';
    if (!clean.endsWith(suffix) || clean.length <= suffix.length) {
      throw const FormatException(
        'Access restricted: Registration and sign-in are exclusively permitted for verified @rice.edu email addresses.',
      );
    }
  }

  /// Decodes claims payload from a JWT token
  static Map<String, dynamic> decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return {};
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _call(String target, Map<String, dynamic> body) async {
    final response = await _httpClient.post(
      Uri.parse(endpoint),
      headers: _headers(target),
      body: jsonEncode(body),
    );

    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        data = {};
      }
    }

    if (response.statusCode != 200) {
      final rawType = (data['__type'] as String? ?? '').split('#').last;
      final message = (data['message'] as String?) ?? (data['Message'] as String?) ?? '';
      _handleCognitoError(rawType, message);
    }
    return data;
  }

  void _handleCognitoError(String errorType, String message) {
    switch (errorType) {
      case 'UserNotConfirmedException':
        throw Exception(
          'UserNotConfirmed: Your account is not confirmed yet. Please enter the verification code sent to your email.',
        );
      case 'NotAuthorizedException':
      case 'UserNotFoundException':
        throw Exception('Incorrect username or password. Please try again.');
      case 'UsernameExistsException':
        throw Exception(
          'An account with this @rice.edu email already exists. Please sign in instead.',
        );
      case 'InvalidPasswordException':
        throw Exception(
          'Password does not meet requirements. Minimum 8 characters with uppercase, numbers, and symbols.',
        );
      case 'UserLambdaValidationException':
        throw Exception(
          'Access restricted: Registration is exclusively permitted for verified @rice.edu email addresses.',
        );
      case 'CodeMismatchException':
        throw Exception('Invalid verification code. Please check the code and try again.');
      case 'ExpiredCodeException':
        throw Exception('Verification code has expired. Please request a new code.');
      case 'InvalidParameterException':
        throw Exception(message.isNotEmpty ? message : 'Invalid request parameters.');
      case 'LimitExceededException':
      case 'TooManyRequestsException':
        throw Exception('Attempt limit exceeded. Please wait a few moments and try again.');
      default:
        throw Exception(message.isNotEmpty ? message : 'An authentication error occurred.');
    }
  }

  /// Sign Up with Email and Password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    validateRiceEmail(cleanEmail);

    final response = await _call('SignUp', {
      'ClientId': clientId,
      'Username': cleanEmail,
      'Password': password,
      'UserAttributes': [
        {'Name': 'email', 'Value': cleanEmail},
        {'Name': 'name', 'Value': displayName.trim()},
      ],
    });
    return response;
  }

  /// Confirm Sign Up with Verification Code (OTP)
  Future<Map<String, dynamic>> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    validateRiceEmail(cleanEmail);

    final response = await _call('ConfirmSignUp', {
      'ClientId': clientId,
      'Username': cleanEmail,
      'ConfirmationCode': confirmationCode.trim(),
    });
    return response;
  }

  /// Resend Verification Code
  Future<Map<String, dynamic>> resendConfirmationCode({required String email}) async {
    final cleanEmail = email.trim().toLowerCase();
    validateRiceEmail(cleanEmail);

    final response = await _call('ResendConfirmationCode', {
      'ClientId': clientId,
      'Username': cleanEmail,
    });
    return response;
  }

  /// Sign In with Email and Password
  Future<RiceUser> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    validateRiceEmail(cleanEmail);

    final res = await _call('InitiateAuth', {
      'AuthFlow': 'USER_PASSWORD_AUTH',
      'ClientId': clientId,
      'AuthParameters': {
        'USERNAME': cleanEmail,
        'PASSWORD': password,
      },
    });

    final authResult = res['AuthenticationResult'] as Map<String, dynamic>? ?? {};
    final idToken = authResult['IdToken'] as String? ?? '';
    final accessToken = authResult['AccessToken'] as String? ?? '';
    final refreshToken = authResult['RefreshToken'] as String?;

    final claims = decodeJwtPayload(idToken);
    final uid = claims['sub'] as String? ?? cleanEmail;
    final emailClaim = claims['email'] as String? ?? cleanEmail;
    final nameClaim = claims['name'] as String? ?? cleanEmail.split('@').first;

    final user = RiceUser(
      uid: uid,
      email: emailClaim,
      displayName: nameClaim.isNotEmpty ? nameClaim : cleanEmail.split('@').first,
      accessToken: accessToken,
      idToken: idToken,
      refreshToken: refreshToken,
    );

    _currentUser = user;
    _saveSession(user);
    _authStateController.add(_currentUser);
    return user;
  }

  /// Request Password Reset Code
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final cleanEmail = email.trim().toLowerCase();
    validateRiceEmail(cleanEmail);

    final response = await _call('ForgotPassword', {
      'ClientId': clientId,
      'Username': cleanEmail,
    });
    return response;
  }

  /// Confirm Password Reset with Code and New Password
  Future<Map<String, dynamic>> confirmForgotPassword({
    required String email,
    required String confirmationCode,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    validateRiceEmail(cleanEmail);

    final response = await _call('ConfirmForgotPassword', {
      'ClientId': clientId,
      'Username': cleanEmail,
      'ConfirmationCode': confirmationCode.trim(),
      'Password': newPassword,
    });
    return response;
  }

  /// Dev Mode Sign In (strictly gated to kDebugMode)
  Future<RiceUser> signInAsDevUser({
    String email = "sammy.owl@rice.edu",
    String displayName = "Sammy the Owl",
  }) async {
    if (!kDebugMode) {
      throw UnsupportedError("Dev mode auth bypass is strictly disabled in production builds.");
    }
    final devUser = RiceUser(
      uid: "rice_demo_uid_1912",
      email: email,
      displayName: displayName,
      photoUrl: null,
    );
    _currentUser = devUser;
    _authStateController.add(_currentUser);
    return devUser;
  }

  /// Global sign-out revoking tokens and clearing local session
  Future<void> signOut() async {
    final token = _currentUser?.accessToken;
    if (token != null && token.isNotEmpty) {
      try {
        await _call('GlobalSignOut', {
          'AccessToken': token,
        });
      } catch (_) {
        // Sign-out locally even if server revoke fails
      }
    }

    _currentUser = null;
    _clearSession();
    _authStateController.add(null);
  }

  void _saveSession(RiceUser user) {
    try {
      _sessionStorage.write(sessionKey, jsonEncode(user.toMap()));
    } catch (_) {}
  }

  void _restoreSession() {
    try {
      final raw = _sessionStorage.read(sessionKey);
      if (raw == null || raw.isEmpty) return;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final user = RiceUser.fromMap(data);

      if (!user.isRiceEmail) {
        _clearSession();
        return;
      }

      // Check JWT expiration if idToken is present
      if (user.idToken != null && user.idToken!.isNotEmpty) {
        final claims = decodeJwtPayload(user.idToken!);
        final exp = claims['exp'];
        if (exp is int) {
          final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          if (expiry.isBefore(DateTime.now())) {
            _clearSession();
            return;
          }
        }
      }

      _currentUser = user;
      _authStateController.add(_currentUser);
    } catch (_) {
      _clearSession();
    }
  }

  void _clearSession() {
    try {
      _sessionStorage.delete(sessionKey);
    } catch (_) {}
  }

  void dispose() {
    _authStateController.close();
    _httpClient.close();
  }
}
