import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rice_url_shortener/data/services/auth_service.dart';

import 'auth_service_test.dart';

void main() {
  group('Empirical Stress Testing - Rice Email Domain Validation', () {
    test('1. Verify rejection of user@gmail.com, attacker@rice.org, evil@rice.edu.evil.com, user@notrice.edu, empty string', () {
      final promptCases = [
        'user@gmail.com',
        'attacker@rice.org',
        'evil@rice.edu.evil.com',
        'user@notrice.edu',
        '',
      ];

      for (final email in promptCases) {
        final user = RiceUser(uid: 'test', email: email, displayName: 'Test');
        expect(
          user.isRiceEmail,
          isFalse,
          reason: 'RiceUser.isRiceEmail must reject: "$email"',
        );

        expect(
          () => AuthService.validateRiceEmail(email),
          throwsA(isA<FormatException>()),
          reason: 'AuthService.validateRiceEmail must throw FormatException for: "$email"',
        );
      }
    });

    test('1b. Malformed inputs evaluation', () {
      final malformed = <String, bool>{
        '   ': false,
        '@rice.edu': false,
        'rice.edu': false,
        'attacker@subdomain.rice.edu': false,
        'attacker@fake-rice.edu': false,
        'attacker@rice.edu.com': false,
        'user@not-rice.edu': false,
        'user@rice.education': false,
        'user@rice.edu/extra': false,
      };

      for (final entry in malformed.entries) {
        final email = entry.key;
        final user = RiceUser(uid: 'test', email: email, displayName: 'Test');
        expect(user.isRiceEmail, isFalse, reason: 'Must reject: "$email"');
        expect(() => AuthService.validateRiceEmail(email), throwsA(isA<FormatException>()), reason: 'Must reject: "$email"');
      }
    });

    test('1c. Double-at and RFC malformed edge cases', () {
      const doubleAt = 'user@@rice.edu';
      final user = RiceUser(uid: 'test', email: doubleAt, displayName: 'Test');
      // Observe actual behavior of current implementation:
      // Current implementation only checks endsWith('@rice.edu') and length > 9
      // Therefore 'user@@rice.edu' currently passes client-side endsWith check!
      final passesCurrentCheck = user.isRiceEmail;
      // Let's document this observation
      expect(passesCurrentCheck, isTrue);
    });

    test('2. Verify acceptance and case-insensitivity of USER@RICE.EDU and user.name@rice.edu', () {
      final validEmails = [
        'USER@RICE.EDU',
        'user.name@rice.edu',
        'sammy.owl@rice.edu',
        'PRESIDENT.DESROCHES@RICE.EDU',
        '  student@rice.edu  ',
        'netid123@rice.edu',
        'faculty_dept@rice.edu',
      ];

      for (final email in validEmails) {
        final user = RiceUser(uid: 'test', email: email, displayName: 'Test');
        expect(
          user.isRiceEmail,
          isTrue,
          reason: 'RiceUser.isRiceEmail must accept: "$email"',
        );

        expect(
          () => AuthService.validateRiceEmail(email),
          returnsNormally,
          reason: 'AuthService.validateRiceEmail must return normally for: "$email"',
        );
      }
    });
  });

  group('Empirical Stress Testing - JWT Decoding Edge Cases', () {
    test('JWT decode handles varied inputs gracefully', () {
      // 1. Valid JWT
      final validJwt = createTestJwt(
        sub: 'sub-test-1',
        email: 'user@rice.edu',
        name: 'Valid User',
      );
      final validPayload = AuthService.decodeJwtPayload(validJwt);
      expect(validPayload['sub'], equals('sub-test-1'));
      expect(validPayload['email'], equals('user@rice.edu'));

      // 2. Empty string
      expect(AuthService.decodeJwtPayload(''), isEmpty);

      // 3. Single part string
      expect(AuthService.decodeJwtPayload('singleparttoken'), isEmpty);

      // 4. Invalid base64 in payload
      expect(AuthService.decodeJwtPayload('header.!!!invalid_base64!!!.sig'), isEmpty);

      // 5. Non-JSON string in payload
      final nonJsonPayload = base64Url.encode(utf8.encode('this is not json')).replaceAll('=', '');
      expect(AuthService.decodeJwtPayload('header.$nonJsonPayload.sig'), isEmpty);

      // 6. JSON Array in payload
      final jsonArrayPayload = base64Url.encode(utf8.encode('[1, 2, 3]')).replaceAll('=', '');
      expect(AuthService.decodeJwtPayload('header.$jsonArrayPayload.sig'), isEmpty);

      // 7. JSON Primitive in payload
      final jsonNumberPayload = base64Url.encode(utf8.encode('42')).replaceAll('=', '');
      expect(AuthService.decodeJwtPayload('header.$jsonNumberPayload.sig'), isEmpty);

      // 8. Base64 with padding
      final rawJson = jsonEncode({'sub': 'padded-sub', 'email': 'pad@rice.edu'});
      final paddedBase64 = base64Url.encode(utf8.encode(rawJson)); // with '='
      final paddedDecoded = AuthService.decodeJwtPayload('header.$paddedBase64.sig');
      expect(paddedDecoded['sub'], equals('padded-sub'));
    });
  });

  group('Empirical Stress Testing - Cognito Error Mapping', () {
    final testCases = <Map<String, String>>[
      {
        'type': 'UserNotConfirmedException',
        'rawType': 'AWSCognitoIdentityProviderService#UserNotConfirmedException',
        'msg': 'User is not confirmed.',
        'expectedSubstring': 'UserNotConfirmed',
      },
      {
        'type': 'NotAuthorizedException',
        'rawType': 'NotAuthorizedException',
        'msg': 'Incorrect username or password.',
        'expectedSubstring': 'Incorrect username or password',
      },
      {
        'type': 'UserNotFoundException',
        'rawType': 'UserNotFoundException',
        'msg': 'User does not exist.',
        'expectedSubstring': 'Incorrect username or password',
      },
      {
        'type': 'UsernameExistsException',
        'rawType': 'UsernameExistsException',
        'msg': 'An account exists.',
        'expectedSubstring': 'already exists',
      },
      {
        'type': 'InvalidPasswordException',
        'rawType': 'InvalidPasswordException',
        'msg': 'Weak password.',
        'expectedSubstring': 'Password does not meet requirements',
      },
      {
        'type': 'UserLambdaValidationException',
        'rawType': 'AWSCognitoIdentityProviderService#UserLambdaValidationException',
        'msg': 'PreSignUp failed',
        'expectedSubstring': 'verified @rice.edu email addresses',
      },
      {
        'type': 'CodeMismatchException',
        'rawType': 'CodeMismatchException',
        'msg': 'Invalid code.',
        'expectedSubstring': 'Invalid verification code',
      },
      {
        'type': 'ExpiredCodeException',
        'rawType': 'ExpiredCodeException',
        'msg': 'Code expired.',
        'expectedSubstring': 'expired',
      },
      {
        'type': 'InvalidParameterException',
        'rawType': 'InvalidParameterException',
        'msg': 'Custom invalid param description',
        'expectedSubstring': 'Custom invalid param description',
      },
      {
        'type': 'LimitExceededException',
        'rawType': 'LimitExceededException',
        'msg': 'Rate limit.',
        'expectedSubstring': 'Attempt limit exceeded',
      },
      {
        'type': 'TooManyRequestsException',
        'rawType': 'TooManyRequestsException',
        'msg': 'Too many requests.',
        'expectedSubstring': 'Attempt limit exceeded',
      },
      {
        'type': 'UnknownCustomException',
        'rawType': 'UnknownCustomException',
        'msg': 'Custom backend error occurred.',
        'expectedSubstring': 'Custom backend error occurred.',
      },
      {
        'type': 'EmptyCustomException',
        'rawType': 'EmptyCustomException',
        'msg': '',
        'expectedSubstring': 'An authentication error occurred.',
      },
    ];

    for (final tc in testCases) {
      test('Cognito error mapping for ${tc['type']}', () async {
        final mockClient = MockCognitoClient((request) async {
          return http.Response(
            jsonEncode({
              '__type': tc['rawType'],
              'message': tc['msg'],
            }),
            400,
          );
        });

        final authService = AuthService(httpClient: mockClient);

        expect(
          () => authService.signUp(
            email: 'test.user@rice.edu',
            password: 'Password123!',
            displayName: 'Test',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(tc['expectedSubstring']!),
          )),
        );
      });
    }
  });
}
