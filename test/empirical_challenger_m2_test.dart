import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rice_url_shortener/core/constants/rice_logos.dart';
import 'package:rice_url_shortener/data/models/qr_config.dart';
import 'package:rice_url_shortener/data/models/short_link.dart';
import 'package:rice_url_shortener/data/services/auth_service.dart';
import 'package:rice_url_shortener/presentation/state/auth_controller.dart';
import 'package:rice_url_shortener/presentation/views/auth/auth_view.dart';

class MockProductionAuthService extends AuthService {
  final bool _simulateNonDebug;
  MockProductionAuthService({this._simulateNonDebug = false})
      : super(sessionStorage: InMemoryAuthSessionStorage());

  @override
  bool get isDevMode => _simulateNonDebug ? false : false;

  @override
  Future<RiceUser> signInAsDevUser({
    String email = "sammy.owl@rice.edu",
    String displayName = "Sammy the Owl",
  }) async {
    if (_simulateNonDebug || !kDebugMode) {
      throw UnsupportedError("Dev mode auth bypass is strictly disabled in production builds.");
    }
    return super.signInAsDevUser(email: email, displayName: displayName);
  }
}

Widget createTestApp(Widget child) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(1440, 900),
        textScaler: TextScaler.linear(0.95),
      ),
      child: child,
    ),
  );
}

void setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Empirical Challenge 1: ShortLink.toJsonMap() and DateTime Serialization', () {
    test('ShortLink.toJsonMap() serializes all DateTime fields to ISO-8601 strings', () {
      final now = DateTime.utc(2026, 10, 20, 21, 15, 30, 500);
      final expires = DateTime.utc(2027, 1, 1, 0, 0, 0);
      final clicked = DateTime.utc(2026, 10, 20, 21, 20, 0);

      final link = ShortLink(
        id: 'test-link-001',
        userId: 'user-rice-123',
        userEmail: 'student@rice.edu',
        shortCode: 'owl26',
        destinationUrl: 'https://rice.edu/admissions',
        fallbackUrl: 'https://rice.edu',
        expiresAt: expires,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        qrConfig: const QrConfig(
          fgColorHex: '#00205B',
          bgColorHex: '#FFFFFF',
          style: QrStyle.rounded,
          logoType: RiceLogoType.owl,
        ),
        clickCount: 42,
        lastClickedAt: clicked,
      );

      final jsonMap = link.toJsonMap();

      // Verify that every DateTime field is a valid ISO-8601 string
      expect(jsonMap['createdAt'], isA<String>());
      expect(jsonMap['updatedAt'], isA<String>());
      expect(jsonMap['expiresAt'], isA<String>());
      expect(jsonMap['lastClickedAt'], isA<String>());

      expect(jsonMap['createdAt'], equals(now.toIso8601String()));
      expect(jsonMap['updatedAt'], equals(now.toIso8601String()));
      expect(jsonMap['expiresAt'], equals(expires.toIso8601String()));
      expect(jsonMap['lastClickedAt'], equals(clicked.toIso8601String()));

      // Validate ISO-8601 string format via regex
      final iso8601Regex = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z?$');
      expect(iso8601Regex.hasMatch(jsonMap['createdAt'] as String), isTrue);
      expect(iso8601Regex.hasMatch(jsonMap['updatedAt'] as String), isTrue);
      expect(iso8601Regex.hasMatch(jsonMap['expiresAt'] as String), isTrue);
      expect(iso8601Regex.hasMatch(jsonMap['lastClickedAt'] as String), isTrue);

      // Verify that jsonEncode succeeds without throwing JsonUnsupportedObjectError
      expect(() => jsonEncode(jsonMap), returnsNormally);
      final encoded = jsonEncode(jsonMap);
      expect(encoded, isA<String>());
      expect(encoded.contains('"shortCode":"owl26"'), isTrue);
    });

    test('ShortLink.toJsonMap() preserves null values for optional DateTime fields', () {
      final now = DateTime.now();
      final link = ShortLink(
        id: 'test-null-dates',
        userId: 'user-rice-456',
        userEmail: 'sammy@rice.edu',
        shortCode: 'sammy',
        destinationUrl: 'https://rice.edu',
        expiresAt: null,
        createdAt: now,
        updatedAt: now,
        lastClickedAt: null,
      );

      final jsonMap = link.toJsonMap();

      expect(jsonMap['expiresAt'], isNull);
      expect(jsonMap['lastClickedAt'], isNull);
      expect(jsonMap['createdAt'], equals(now.toIso8601String()));
      expect(jsonMap['updatedAt'], equals(now.toIso8601String()));

      expect(() => jsonEncode(jsonMap), returnsNormally);
    });

    test('ShortLink.toMap() delegates to toJsonMap() and succeeds on jsonEncode', () {
      final now = DateTime.now();
      final link = ShortLink(
        id: 'map-serialization-test',
        userId: 'user-1',
        userEmail: 'test@rice.edu',
        shortCode: 'maptest',
        destinationUrl: 'https://rice.edu',
        createdAt: now,
        updatedAt: now,
      );

      final map = link.toMap();

      expect(map['createdAt'], isA<String>());
      expect(map['updatedAt'], isA<String>());
      expect(() => jsonEncode(map), returnsNormally);
    });

    test('Round-trip fidelity: ShortLink -> toJsonMap -> jsonEncode -> jsonDecode -> fromMap', () {
      final created = DateTime.utc(2026, 5, 10, 14, 30, 0);
      final updated = DateTime.utc(2026, 5, 11, 8, 15, 0);
      final expires = DateTime.utc(2026, 12, 31, 23, 59, 59);
      final clicked = DateTime.utc(2026, 6, 1, 12, 0, 0);

      final original = ShortLink(
        id: 'roundtrip-link-id',
        userId: 'faculty-999',
        userEmail: 'professor@rice.edu',
        shortCode: 'course101',
        destinationUrl: 'https://canvas.rice.edu/courses/101',
        fallbackUrl: 'https://canvas.rice.edu',
        expiresAt: expires,
        isActive: false,
        createdAt: created,
        updatedAt: updated,
        qrConfig: const QrConfig(
          fgColorHex: '#C19B4C',
          bgColorHex: '#00205B',
          style: QrStyle.dots,
          logoType: RiceLogoType.oldEnglishR,
        ),
        clickCount: 1337,
        lastClickedAt: clicked,
      );

      final jsonMap = original.toJsonMap();
      final encodedString = jsonEncode(jsonMap);
      final decodedMap = jsonDecode(encodedString) as Map<String, dynamic>;
      final reconstructed = ShortLink.fromMap(decodedMap);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.userId, equals(original.userId));
      expect(reconstructed.userEmail, equals(original.userEmail));
      expect(reconstructed.shortCode, equals(original.shortCode));
      expect(reconstructed.destinationUrl, equals(original.destinationUrl));
      expect(reconstructed.fallbackUrl, equals(original.fallbackUrl));
      expect(reconstructed.isActive, equals(original.isActive));
      expect(reconstructed.clickCount, equals(original.clickCount));

      // Check DateTime round-trip values
      expect(reconstructed.createdAt.toUtc(), equals(created));
      expect(reconstructed.updatedAt.toUtc(), equals(updated));
      expect(reconstructed.expiresAt!.toUtc(), equals(expires));
      expect(reconstructed.lastClickedAt!.toUtc(), equals(clicked));

      // Check QR config
      expect(reconstructed.qrConfig.fgColorHex, equals('#C19B4C'));
      expect(reconstructed.qrConfig.bgColorHex, equals('#00205B'));
      expect(reconstructed.qrConfig.style, equals(QrStyle.dots));
      expect(reconstructed.qrConfig.logoType, equals(RiceLogoType.oldEnglishR));
    });

    test('Stress Test Generator: 500 randomized ShortLink instances serialized and encoded', () {
      final random = Random(42);
      final styles = QrStyle.values;
      final logos = RiceLogoType.values;

      for (int i = 0; i < 500; i++) {
        final hasExpires = random.nextBool();
        final hasClicked = random.nextBool();
        final isUtc = random.nextBool();

        DateTime makeDate(int yearOffset, int month, int day, int hour, int minute, int second) {
          final dt = DateTime(2020 + yearOffset, month, day, hour, minute, second);
          return isUtc ? dt.toUtc() : dt;
        }

        final link = ShortLink(
          id: 'link-$i-${random.nextInt(100000)}',
          userId: 'user-${random.nextInt(1000)}',
          userEmail: 'user_${random.nextInt(100)}@rice.edu',
          shortCode: 'code$i',
          destinationUrl: 'https://rice.edu/path/$i?query=param${random.nextInt(50)}',
          fallbackUrl: 'https://rice.edu/fallback',
          expiresAt: hasExpires ? makeDate(random.nextInt(10), (i % 12) + 1, (i % 28) + 1, i % 24, i % 60, i % 60) : null,
          isActive: random.nextBool(),
          createdAt: makeDate(0, 1, 1, 0, 0, 0),
          updatedAt: makeDate(1, 2, 3, 4, 5, 6),
          qrConfig: QrConfig(
            fgColorHex: '#00205B',
            bgColorHex: '#FFFFFF',
            style: styles[i % styles.length],
            logoType: logos[i % logos.length],
          ),
          clickCount: random.nextInt(1000000),
          lastClickedAt: hasClicked ? makeDate(2, 3, 4, 5, 6, 7) : null,
        );

        final jsonMap = link.toJsonMap();
        expect(() => jsonEncode(jsonMap), returnsNormally, reason: 'Failed at iteration $i');
        final decoded = jsonDecode(jsonEncode(jsonMap)) as Map<String, dynamic>;
        final restored = ShortLink.fromMap(decoded);

        expect(restored.shortCode, equals(link.shortCode));
        expect(restored.destinationUrl, equals(link.destinationUrl));
        expect(restored.isActive, equals(link.isActive));
        expect(restored.clickCount, equals(link.clickCount));
        if (hasExpires) {
          expect(restored.expiresAt, isNotNull);
        } else {
          expect(restored.expiresAt, isNull);
        }
      }
    });

    test('ShortLink.fromMap handles malformed or unexpected date formats defensively', () {
      final fallbackNow = DateTime.now();

      // Case 1: Dates are invalid strings
      final malformedMap = {
        'id': 'malformed-link',
        'userId': 'u1',
        'userEmail': 'u@rice.edu',
        'shortCode': 'bad-date',
        'destinationUrl': 'https://rice.edu',
        'createdAt': 'not-a-valid-date-string',
        'updatedAt': 123456789, // non-string, non-Timestamp
        'expiresAt': 'invalid-date',
        'lastClickedAt': ['array', 'unexpected'],
      };

      final link = ShortLink.fromMap(malformedMap);
      expect(link.id, equals('malformed-link'));
      // fallback handled gracefully
      expect(link.createdAt.difference(fallbackNow).inSeconds.abs() <= 5, isTrue);
      expect(link.updatedAt.difference(fallbackNow).inSeconds.abs() <= 5, isTrue);
      expect(link.expiresAt, isNull);
      expect(link.lastClickedAt, isNull);
    });
  });

  group('Empirical Challenge 2: AuthView UI Modes and Dev Bypass Absence', () {
    late InMemoryAuthSessionStorage sessionStorage;

    setUp(() {
      sessionStorage = InMemoryAuthSessionStorage();
    });

    testWidgets('Mode 1: signIn mode renders email/password and Sign In action', (tester) async {
      setDesktopViewport(tester);
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      await tester.pumpWidget(createTestApp(AuthView(
        authController: controller,
        initialMode: AuthViewMode.signIn,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Rice Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Register with @rice.edu'), findsOneWidget);
    });

    testWidgets('Mode 2: signUp mode renders name, email, password, confirm password', (tester) async {
      setDesktopViewport(tester);
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      await tester.pumpWidget(createTestApp(AuthView(
        authController: controller,
        initialMode: AuthViewMode.signUp,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Rice Email Address'), findsOneWidget);
      expect(find.text('Password (min 8 characters)'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
    });

    testWidgets('Mode 3: confirmSignUp mode renders OTP verification code input', (tester) async {
      setDesktopViewport(tester);
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      await tester.pumpWidget(createTestApp(AuthView(
        authController: controller,
        initialMode: AuthViewMode.confirmSignUp,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Account'), findsOneWidget);
      expect(find.text('Verification Code (from email)'), findsOneWidget);
      expect(find.text('Resend Code'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
    });

    testWidgets('Mode 4: forgotPassword mode renders email input and send code action', (tester) async {
      setDesktopViewport(tester);
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      await tester.pumpWidget(createTestApp(AuthView(
        authController: controller,
        initialMode: AuthViewMode.forgotPassword,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Send Reset Code'), findsOneWidget);
      expect(find.text('Rice Email Address'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
    });

    testWidgets('Mode 5: confirmForgotPassword mode renders OTP and new password inputs', (tester) async {
      setDesktopViewport(tester);
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      await tester.pumpWidget(createTestApp(AuthView(
        authController: controller,
        initialMode: AuthViewMode.confirmForgotPassword,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Set New Password'), findsOneWidget);
      expect(find.text('Password Reset Code'), findsOneWidget);
      expect(find.text('New Password (min 8 characters)'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
    });

    testWidgets('Dev Bypass Absence: Button is completely absent across ALL 5 modes in production', (tester) async {
      setDesktopViewport(tester);
      final productionService = MockProductionAuthService();
      final controller = AuthController(authService: productionService);

      expect(controller.isDevMode, isFalse);

      final modes = [
        AuthViewMode.signIn,
        AuthViewMode.signUp,
        AuthViewMode.confirmSignUp,
        AuthViewMode.forgotPassword,
        AuthViewMode.confirmForgotPassword,
      ];

      for (final mode in modes) {
        await tester.pumpWidget(createTestApp(AuthView(
          authController: controller,
          initialMode: mode,
        )));
        await tester.pumpAndSettle();

        // In every single mode, the dev bypass button and icon MUST be completely absent
        expect(
          find.text('Bypass Auth (Dev Mode)'),
          findsNothing,
          reason: 'Bypass button must not exist in mode $mode when isDevMode is false',
        );
        expect(
          find.byIcon(Icons.developer_mode_rounded),
          findsNothing,
          reason: 'Developer mode icon must not exist in mode $mode when isDevMode is false',
        );
      }
    });

    test('Dev Bypass Runtime Defense: signInAsDevUser throws UnsupportedError when not in debug', () async {
      final productionService = MockProductionAuthService(simulateNonDebug: true);
      expect(
        () => productionService.signInAsDevUser(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('Adversarial Email Fuzzer: AuthService.validateRiceEmail rejects all malicious variants', () {
      final invalidEmails = [
        'student@gmail.com',
        'faculty@yahoo.com',
        'hacker@outlook.com',
        'admin@rice.edu.evil.com',
        'spoof@rice.edu.attacker.org',
        'rice.edu@fake.com',
        '@rice.edu',
        '  @rice.edu',
        '',
        '   ',
        'rice.edu',
        'user@riceedu',
        'user@subdomain.rice.edu.attacker.com',
        'attacker@not-rice.edu',
      ];

      for (final email in invalidEmails) {
        expect(
          () => AuthService.validateRiceEmail(email),
          throwsA(isA<FormatException>()),
          reason: 'Email "$email" should have been rejected as non-Rice',
        );
      }

      final validEmails = [
        'sammy@rice.edu',
        'john.doe@rice.edu',
        'SAMMY@RICE.EDU',
        'Faculty.Member_12@rice.edu',
        '  netid@rice.edu  ',
      ];

      for (final email in validEmails) {
        expect(
          () => AuthService.validateRiceEmail(email),
          returnsNormally,
          reason: 'Valid email "$email" should be accepted',
        );
      }
    });
  });
}
