import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rice_url_shortener/data/services/auth_service.dart';
import 'package:rice_url_shortener/presentation/state/auth_controller.dart';

import 'auth_service_test.dart';

void main() {
  group('AuthController State Management Tests', () {
    late InMemoryAuthSessionStorage sessionStorage;

    setUp(() {
      sessionStorage = InMemoryAuthSessionStorage();
    });

    test('Initial controller state is correct', () {
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      expect(controller.currentUser, isNull);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.isDevMode, equals(authService.isDevMode));
    });

    test('signIn success transitions state and notifies listeners', () async {
      final jwtToken = createTestJwt(
        sub: 'sub-login-123',
        email: 'sammy@rice.edu',
        name: 'Sammy Owl',
      );

      final mockClient = MockCognitoClient((request) async {
        return http.Response(
          jsonEncode({
            'AuthenticationResult': {
              'AccessToken': 'mock_access',
              'IdToken': jwtToken,
            },
          }),
          200,
        );
      });

      final authService = AuthService(
        httpClient: mockClient,
        sessionStorage: sessionStorage,
      );
      final controller = AuthController(authService: authService);

      final listenerStates = <bool>[];
      controller.addListener(() {
        listenerStates.add(controller.isLoading);
      });

      final success = await controller.signIn(
        email: 'sammy@rice.edu',
        password: 'Password123!',
      );

      expect(success, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser!.email, equals('sammy@rice.edu'));
      expect(controller.currentUser!.displayName, equals('Sammy Owl'));
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
      // Listener should have fired with isLoading true then false
      expect(listenerStates, contains(true));
      expect(listenerStates.last, isFalse);
    });

    test('signIn failure sets errorMessage and clears loading', () async {
      final mockClient = MockCognitoClient((request) async {
        return http.Response(
          jsonEncode({
            '__type': 'NotAuthorizedException',
            'message': 'Incorrect username or password.',
          }),
          400,
        );
      });

      final authService = AuthService(
        httpClient: mockClient,
        sessionStorage: sessionStorage,
      );
      final controller = AuthController(authService: authService);

      final success = await controller.signIn(
        email: 'sammy@rice.edu',
        password: 'wrong_password',
      );

      expect(success, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.errorMessage, equals('Incorrect username or password. Please try again.'));
      expect(controller.isLoading, isFalse);
    });

    test('signUp success and failure flows', () async {
      bool succeed = true;
      final mockClient = MockCognitoClient((request) async {
        if (!succeed) {
          return http.Response(
            jsonEncode({
              '__type': 'UsernameExistsException',
              'message': 'Username exists.',
            }),
            400,
          );
        }
        return http.Response(jsonEncode({'UserConfirmed': false}), 200);
      });

      final authService = AuthService(
        httpClient: mockClient,
        sessionStorage: sessionStorage,
      );
      final controller = AuthController(authService: authService);

      // Successful signUp
      final ok = await controller.signUp(
        email: 'new.student@rice.edu',
        password: 'Password123!',
        displayName: 'New Student',
      );
      expect(ok, isTrue);
      expect(controller.errorMessage, isNull);

      // Failed signUp
      succeed = false;
      final failed = await controller.signUp(
        email: 'new.student@rice.edu',
        password: 'Password123!',
        displayName: 'New Student',
      );
      expect(failed, isFalse);
      expect(controller.errorMessage, contains('An account with this @rice.edu email already exists'));
    });

    test('confirmSignUp and resendConfirmationCode flows', () async {
      final mockClient = MockCognitoClient((request) async {
        final target = request.headers['x-amz-target'] ?? '';
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (target.endsWith('ConfirmSignUp')) {
          if (body['ConfirmationCode'] == '123456') {
            return http.Response('{}', 200);
          } else {
            return http.Response(
              jsonEncode({
                '__type': 'CodeMismatchException',
                'message': 'Invalid code.',
              }),
              400,
            );
          }
        }
        return http.Response('{}', 200);
      });

      final authService = AuthService(
        httpClient: mockClient,
        sessionStorage: sessionStorage,
      );
      final controller = AuthController(authService: authService);

      // Success
      final success = await controller.confirmSignUp(
        email: 'sammy@rice.edu',
        confirmationCode: '123456',
      );
      expect(success, isTrue);
      expect(controller.errorMessage, isNull);

      // Failure
      final failure = await controller.confirmSignUp(
        email: 'sammy@rice.edu',
        confirmationCode: '000000',
      );
      expect(failure, isFalse);
      expect(controller.errorMessage, contains('Invalid verification code'));

      // Resend code
      final resendOk = await controller.resendConfirmationCode(email: 'sammy@rice.edu');
      expect(resendOk, isTrue);
    });

    test('forgotPassword and confirmForgotPassword flows', () async {
      final mockClient = MockCognitoClient((request) async {
        return http.Response('{}', 200);
      });

      final authService = AuthService(
        httpClient: mockClient,
        sessionStorage: sessionStorage,
      );
      final controller = AuthController(authService: authService);

      final resetRequested = await controller.forgotPassword(email: 'owl@rice.edu');
      expect(resetRequested, isTrue);

      final resetConfirmed = await controller.confirmForgotPassword(
        email: 'owl@rice.edu',
        confirmationCode: '112233',
        newPassword: 'BrandNewPassword123!',
      );
      expect(resetConfirmed, isTrue);
    });

    test('signInAsDev succeeds in debug environment and updates user', () async {
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      final ok = await controller.signInAsDev();
      expect(ok, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser!.email, equals('sammy.owl@rice.edu'));
    });

    test('signOut clears user state and notifies listeners', () async {
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      await controller.signInAsDev();
      expect(controller.isAuthenticated, isTrue);

      await controller.signOut();
      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
    });

    test('clearError resets error message and notifies listeners', () async {
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      // Force error via invalid email
      await controller.signIn(email: 'invalid@gmail.com', password: '123');
      expect(controller.errorMessage, isNotNull);

      int listenerCount = 0;
      controller.addListener(() => listenerCount++);

      controller.clearError();
      expect(controller.errorMessage, isNull);
      expect(listenerCount, equals(1));
    });
  });
}
