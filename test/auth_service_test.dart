import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rice_url_shortener/data/services/auth_service.dart';
import 'package:rice_url_shortener/data/models/short_link.dart';

/// Helper to create a valid unexpired JWT IdToken for testing claims parsing
String createTestJwt({
  required String sub,
  required String email,
  required String name,
  int? exp,
}) {
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'RS256', 'typ': 'JWT'}))).replaceAll('=', '');
  final expiry = exp ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600);
  final payload = base64Url.encode(utf8.encode(jsonEncode({
    'sub': sub,
    'email': email,
    'name': name,
    'exp': expiry,
    'token_use': 'id',
  }))).replaceAll('=', '');
  return '$header.$payload.mock_signature_bytes';
}

/// Mock HTTP Client for intercepting and verifying AWS Cognito JSON-RPC calls
class MockCognitoClient extends http.BaseClient {
  final Future<http.Response> Function(http.Request request) handler;

  MockCognitoClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final httpRequest = request as http.Request;
    final response = await handler(httpRequest);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('AuthService - Rice Email Domain Validation', () {
    test('RiceUser.isRiceEmail accepts valid Rice email addresses', () {
      const user1 = RiceUser(uid: '1', email: 'sammy@rice.edu', displayName: 'Sammy');
      expect(user1.isRiceEmail, isTrue);

      const user2 = RiceUser(uid: '2', email: 'SAMMY.OWL@RICE.EDU', displayName: 'Sammy');
      expect(user2.isRiceEmail, isTrue);

      const user3 = RiceUser(uid: '3', email: 'president.desroches@rice.edu', displayName: 'President');
      expect(user3.isRiceEmail, isTrue);
    });

    test('RiceUser.isRiceEmail rejects non-Rice and spoofed email addresses', () {
      const gUser = RiceUser(uid: '1', email: 'sammy@gmail.com', displayName: 'Sammy');
      expect(gUser.isRiceEmail, isFalse);

      const orgUser = RiceUser(uid: '2', email: 'user@rice.org', displayName: 'User');
      expect(orgUser.isRiceEmail, isFalse);

      const evilUser = RiceUser(uid: '3', email: 'attacker@rice.edu.evil.com', displayName: 'Evil');
      expect(evilUser.isRiceEmail, isFalse);

      const prefixUser = RiceUser(uid: '4', email: 'rice.edu@yahoo.com', displayName: 'Prefix');
      expect(prefixUser.isRiceEmail, isFalse);

      const emptyUser = RiceUser(uid: '5', email: '', displayName: 'Empty');
      expect(emptyUser.isRiceEmail, isFalse);

      const bareDomain = RiceUser(uid: '6', email: '@rice.edu', displayName: 'Bare');
      expect(bareDomain.isRiceEmail, isFalse);
    });

    test('AuthService.validateRiceEmail validates correctly', () {
      expect(() => AuthService.validateRiceEmail('owl@rice.edu'), returnsNormally);
      expect(() => AuthService.validateRiceEmail('OWL@RICE.EDU'), returnsNormally);

      expect(
        () => AuthService.validateRiceEmail('user@gmail.com'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('verified @rice.edu email addresses'),
        )),
      );

      expect(
        () => AuthService.validateRiceEmail('@rice.edu'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('AuthService - Production Security & Dev Mode Guard', () {
    test('isDevMode matches kDebugMode', () {
      final authService = AuthService();
      expect(authService.isDevMode, equals(kDebugMode));
    });

    test('signInAsDevUser creates dev RiceUser in debug mode', () async {
      final authService = AuthService();
      final user = await authService.signInAsDevUser();

      expect(user.uid, equals('rice_demo_uid_1912'));
      expect(user.email, equals('sammy.owl@rice.edu'));
      expect(user.displayName, equals('Sammy the Owl'));
      expect(user.isRiceEmail, isTrue);
      expect(authService.currentUser, equals(user));
    });
  });

  group('AuthService - AWS Cognito JSON-RPC HTTP REST Operations', () {
    late InMemoryAuthSessionStorage sessionStorage;

    setUp(() {
      sessionStorage = InMemoryAuthSessionStorage();
    });

    test('signUp sends valid AWSCognitoIdentityProviderService.SignUp request', () async {
      late http.Request capturedRequest;

      final mockClient = MockCognitoClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'UserConfirmed': false,
            'UserSub': 'cognito-sub-1912',
          }),
          200,
          headers: {'content-type': 'application/x-amz-json-1.1'},
        );
      });

      final authService = AuthService(
        httpClient: mockClient,
        sessionStorage: sessionStorage,
      );

      final result = await authService.signUp(
        email: 'sammy@rice.edu',
        password: 'Password123!',
        displayName: 'Sammy Owl',
      );

      expect(result['UserConfirmed'], isFalse);
      expect(capturedRequest.url.toString(), equals('https://cognito-idp.us-east-2.amazonaws.com/'));
      expect(capturedRequest.headers['x-amz-target'], equals('AWSCognitoIdentityProviderService.SignUp'));
      expect(capturedRequest.headers['content-type'], equals('application/x-amz-json-1.1'));

      final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(body['Username'], equals('sammy@rice.edu'));
      expect(body['Password'], equals('Password123!'));
      expect(body['ClientId'], equals('4fo9g0ld8p6i0lkojb4s828hjr'));
      expect(body['UserAttributes'], isList);
    });

    test('signUp immediately rejects non-Rice emails without network request', () async {
      bool networkCalled = false;
      final mockClient = MockCognitoClient((request) async {
        networkCalled = true;
        return http.Response('{}', 200);
      });

      final authService = AuthService(
        httpClient: mockClient,
        sessionStorage: sessionStorage,
      );

      expect(
        () => authService.signUp(
          email: 'attacker@gmail.com',
          password: 'Password123!',
          displayName: 'Attacker',
        ),
        throwsA(isA<FormatException>()),
      );
      expect(networkCalled, isFalse);
    });

    test('confirmSignUp sends AWSCognitoIdentityProviderService.ConfirmSignUp request', () async {
      late http.Request capturedRequest;

      final mockClient = MockCognitoClient((request) async {
        capturedRequest = request;
        return http.Response('{}', 200);
      });

      final authService = AuthService(
        httpClient: mockClient,
        sessionStorage: sessionStorage,
      );

      await authService.confirmSignUp(
        email: 'sammy@rice.edu',
        confirmationCode: '123456',
      );

      expect(capturedRequest.headers['x-amz-target'], equals('AWSCognitoIdentityProviderService.ConfirmSignUp'));
      final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(body['Username'], equals('sammy@rice.edu'));
      expect(body['ConfirmationCode'], equals('123456'));
    });

    test('resendConfirmationCode sends AWSCognitoIdentityProviderService.ResendConfirmationCode', () async {
      late http.Request capturedRequest;

      final mockClient = MockCognitoClient((request) async {
        capturedRequest = request;
        return http.Response('{}', 200);
      });

      final authService = AuthService(
        httpClient: mockClient,
        sessionStorage: sessionStorage,
      );

      await authService.resendConfirmationCode(email: 'sammy@rice.edu');

      expect(capturedRequest.headers['x-amz-target'], equals('AWSCognitoIdentityProviderService.ResendConfirmationCode'));
      final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(body['Username'], equals('sammy@rice.edu'));
    });

    test('signInWithPassword authenticates, parses JWT claims, and saves session', () async {
      final jwtToken = createTestJwt(
        sub: 'sub-rice-999',
        email: 'sammy@rice.edu',
        name: 'Sammy The Owl',
      );

      final mockClient = MockCognitoClient((request) async {
        return http.Response(
          jsonEncode({
            'AuthenticationResult': {
              'AccessToken': 'mock_access_token_123',
              'IdToken': jwtToken,
              'RefreshToken': 'mock_refresh_token_456',
              'ExpiresIn': 3600,
              'TokenType': 'Bearer',
            },
          }),
          200,
        );
      });

      final authService = AuthService(
        httpClient: mockClient,
        sessionStorage: sessionStorage,
      );

      final user = await authService.signInWithPassword(
        email: 'sammy@rice.edu',
        password: 'Password123!',
      );

      expect(user.uid, equals('sub-rice-999'));
      expect(user.email, equals('sammy@rice.edu'));
      expect(user.displayName, equals('Sammy The Owl'));
      expect(user.accessToken, equals('mock_access_token_123'));
      expect(user.idToken, equals(jwtToken));
      expect(authService.currentUser, equals(user));

      // Verify persistent session storage
      expect(sessionStorage.read(AuthService.sessionKey), isNotNull);
      final storedData = jsonDecode(sessionStorage.read(AuthService.sessionKey)!);
      expect(storedData['uid'], equals('sub-rice-999'));
      expect(storedData['email'], equals('sammy@rice.edu'));
    });

    test('forgotPassword and confirmForgotPassword send proper Cognito targets', () async {
      final targets = <String>[];

      final mockClient = MockCognitoClient((request) async {
        targets.add(request.headers['x-amz-target'] ?? '');
        return http.Response('{}', 200);
      });

      final authService = AuthService(
        httpClient: mockClient,
        sessionStorage: sessionStorage,
      );

      await authService.forgotPassword(email: 'sammy@rice.edu');
      await authService.confirmForgotPassword(
        email: 'sammy@rice.edu',
        confirmationCode: '654321',
        newPassword: 'NewPassword123!',
      );

      expect(targets, contains('AWSCognitoIdentityProviderService.ForgotPassword'));
      expect(targets, contains('AWSCognitoIdentityProviderService.ConfirmForgotPassword'));
    });

    test('signOut revokes token and clears session', () async {
      final jwtToken = createTestJwt(
        sub: 'sub-rice-999',
        email: 'sammy@rice.edu',
        name: 'Sammy The Owl',
      );

      bool globalSignOutCalled = false;
      final mockClient = MockCognitoClient((request) async {
        if (request.headers['x-amz-target'] == 'AWSCognitoIdentityProviderService.InitiateAuth') {
          return http.Response(
            jsonEncode({
              'AuthenticationResult': {
                'AccessToken': 'mock_access_token',
                'IdToken': jwtToken,
              },
            }),
            200,
          );
        }
        if (request.headers['x-amz-target'] == 'AWSCognitoIdentityProviderService.GlobalSignOut') {
          globalSignOutCalled = true;
          return http.Response('{}', 200);
        }
        return http.Response('{}', 200);
      });

      final authService = AuthService(
        httpClient: mockClient,
        sessionStorage: sessionStorage,
      );

      await authService.signInWithPassword(email: 'sammy@rice.edu', password: 'pwd');
      expect(authService.currentUser, isNotNull);

      await authService.signOut();
      expect(globalSignOutCalled, isTrue);
      expect(authService.currentUser, isNull);
      expect(sessionStorage.read(AuthService.sessionKey), isNull);
    });
  });

  group('AuthService - Cognito Error Handling', () {
    test('handles UserLambdaValidationException for non-Rice rejection', () async {
      final mockClient = MockCognitoClient((request) async {
        return http.Response(
          jsonEncode({
            '__type': 'UserLambdaValidationException',
            'message': 'PreSignUp failed with error: Access restricted: Registration is exclusively permitted for verified @rice.edu email addresses.',
          }),
          400,
        );
      });

      final authService = AuthService(httpClient: mockClient);

      expect(
        () => authService.signUp(
          email: 'valid.rice@rice.edu',
          password: 'pwd',
          displayName: 'Test',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'error',
          contains('verified @rice.edu email addresses'),
        )),
      );
    });

    test('handles UserNotConfirmedException', () async {
      final mockClient = MockCognitoClient((request) async {
        return http.Response(
          jsonEncode({
            '__type': 'UserNotConfirmedException',
            'message': 'User is not confirmed.',
          }),
          400,
        );
      });

      final authService = AuthService(httpClient: mockClient);

      expect(
        () => authService.signInWithPassword(email: 'user@rice.edu', password: 'pwd'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'error',
          contains('UserNotConfirmed'),
        )),
      );
    });

    test('handles NotAuthorizedException and UsernameExistsException', () async {
      final mockClient = MockCognitoClient((request) async {
        return http.Response(
          jsonEncode({
            '__type': 'NotAuthorizedException',
            'message': 'Incorrect username or password.',
          }),
          400,
        );
      });

      final authService = AuthService(httpClient: mockClient);

      expect(
        () => authService.signInWithPassword(email: 'user@rice.edu', password: 'pwd'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'error',
          contains('Incorrect username or password'),
        )),
      );
    });
  });

  group('AuthService - Session Persistence Across Restarts', () {
    test('restores valid session from storage on startup', () {
      final storage = InMemoryAuthSessionStorage();
      final jwtToken = createTestJwt(
        sub: 'sub-persisted-123',
        email: 'saved.user@rice.edu',
        name: 'Saved User',
      );

      final user = RiceUser(
        uid: 'sub-persisted-123',
        email: 'saved.user@rice.edu',
        displayName: 'Saved User',
        idToken: jwtToken,
        accessToken: 'saved_access_token',
      );

      storage.write(AuthService.sessionKey, jsonEncode(user.toMap()));

      // Initialize brand new AuthService instance with same storage
      final newAuthService = AuthService(sessionStorage: storage);

      expect(newAuthService.currentUser, isNotNull);
      expect(newAuthService.currentUser!.uid, equals('sub-persisted-123'));
      expect(newAuthService.currentUser!.email, equals('saved.user@rice.edu'));
      expect(newAuthService.currentUser!.displayName, equals('Saved User'));
    });

    test('discards expired session on startup', () {
      final storage = InMemoryAuthSessionStorage();
      final expiredJwt = createTestJwt(
        sub: 'sub-expired-123',
        email: 'expired.user@rice.edu',
        name: 'Expired User',
        exp: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600, // 1 hour ago
      );

      final user = RiceUser(
        uid: 'sub-expired-123',
        email: 'expired.user@rice.edu',
        displayName: 'Expired User',
        idToken: expiredJwt,
      );

      storage.write(AuthService.sessionKey, jsonEncode(user.toMap()));

      final authService = AuthService(sessionStorage: storage);
      expect(authService.currentUser, isNull);
      expect(storage.read(AuthService.sessionKey), isNull);
    });
  });

  group('ShortLink - JSON RPC Serialization (TEST_READY Escalation Fix)', () {
    test('toJsonMap serializes dates to ISO-8601 strings and is encodable by jsonEncode', () {
      final now = DateTime.now();
      final expires = now.add(const Duration(days: 30));
      final link = ShortLink(
        id: 'campanile',
        userId: 'rice_u1',
        userEmail: 'sammy@rice.edu',
        shortCode: 'campanile',
        destinationUrl: 'https://rice.edu/about',
        fallbackUrl: 'https://rice.edu',
        expiresAt: expires,
        createdAt: now,
        updatedAt: now,
        lastClickedAt: now,
        clickCount: 1912,
      );

      final jsonMap = link.toJsonMap();
      expect(jsonMap['expiresAt'], isA<String>());
      expect(jsonMap['createdAt'], isA<String>());
      expect(jsonMap['updatedAt'], isA<String>());
      expect(jsonMap['lastClickedAt'], isA<String>());

      // jsonEncode must NOT throw JsonUnsupportedObjectError
      final jsonString = jsonEncode(jsonMap);
      expect(jsonString, isNotEmpty);

      // Deserializing back with ShortLink.fromMap restores DateTime objects
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = ShortLink.fromMap(decoded);

      expect(restored.id, equals('campanile'));
      expect(restored.shortCode, equals('campanile'));
      expect(restored.clickCount, equals(1912));
      expect(restored.expiresAt, isNotNull);
      expect(restored.expiresAt!.difference(expires).inSeconds.abs(), lessThan(2));
      expect(restored.createdAt.difference(now).inSeconds.abs(), lessThan(2));
      expect(restored.lastClickedAt, isNotNull);
    });
  });
}
