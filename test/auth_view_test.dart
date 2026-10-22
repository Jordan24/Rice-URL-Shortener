import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rice_url_shortener/data/services/auth_service.dart';
import 'package:rice_url_shortener/presentation/state/auth_controller.dart';
import 'package:rice_url_shortener/presentation/views/auth/auth_view.dart';

class MockProductionAuthService extends AuthService {
  @override
  bool get isDevMode => false;
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
  group('AuthView UI and Mode Transitions', () {
    late InMemoryAuthSessionStorage sessionStorage;

    setUp(() {
      sessionStorage = InMemoryAuthSessionStorage();
    });

    testWidgets('renders institutional Rice banner and SignIn form by default', (tester) async {
      setDesktopViewport(tester);
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      await tester.pumpWidget(createTestApp(AuthView(authController: controller)));
      await tester.pumpAndSettle();

      expect(find.text('RICE UNIVERSITY'), findsOneWidget);
      expect(find.text('URL Shortener & QR Studio'), findsOneWidget);
      expect(find.text('Rice Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Register with @rice.edu'), findsOneWidget);
      expect(find.text('Restricted to verified @rice.edu email accounts.'), findsOneWidget);
    });

    testWidgets('switches to SignUp mode when clicking Register', (tester) async {
      setDesktopViewport(tester);
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      await tester.pumpWidget(createTestApp(AuthView(authController: controller)));
      await tester.pumpAndSettle();

      final registerButton = find.text('Register with @rice.edu');
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Password (min 8 characters)'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
    });

    testWidgets('switches to ForgotPassword mode and back', (tester) async {
      setDesktopViewport(tester);
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      await tester.pumpWidget(createTestApp(AuthView(authController: controller)));
      await tester.pumpAndSettle();

      final forgotButton = find.text('Forgot password?');
      await tester.ensureVisible(forgotButton);
      await tester.tap(forgotButton);
      await tester.pumpAndSettle();

      expect(find.text('Send Reset Code'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);

      final backButton = find.text('Back to Sign In');
      await tester.ensureVisible(backButton);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('renders ConfirmSignUp mode with verification code input', (tester) async {
      setDesktopViewport(tester);
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      await tester.pumpWidget(createTestApp(AuthView(
        authController: controller,
        initialMode: AuthViewMode.confirmSignUp,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Verification Code (from email)'), findsOneWidget);
      expect(find.text('Confirm Account'), findsOneWidget);
      expect(find.text('Resend Code'), findsOneWidget);
    });

    testWidgets('client-side validation rejects non-Rice emails with institutional message', (tester) async {
      setDesktopViewport(tester);
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      await tester.pumpWidget(createTestApp(AuthView(authController: controller)));
      await tester.pumpAndSettle();

      // Enter a non-Rice email
      final emailField = find.widgetWithText(TextField, 'netid@rice.edu');
      await tester.enterText(emailField, 'student@gmail.com');

      final passwordField = find.widgetWithText(TextField, '••••••••');
      await tester.enterText(passwordField, 'Password123!');

      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.ensureVisible(signInButton);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Validation error displayed in UI
      expect(find.textContaining('Registration and sign-in are exclusively permitted for verified @rice.edu email addresses.'), findsOneWidget);
    });

    testWidgets('submits sign-in form when pressing Enter in password field', (tester) async {
      setDesktopViewport(tester);
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      await tester.pumpWidget(createTestApp(AuthView(authController: controller)));
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextField, 'netid@rice.edu');
      await tester.enterText(emailField, 'student@gmail.com');

      final passwordField = find.widgetWithText(TextField, '••••••••');
      await tester.tap(passwordField);
      await tester.enterText(passwordField, 'Password123!');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Submitting via Enter triggers _handleSignIn and runs validation
      expect(find.textContaining('Registration and sign-in are exclusively permitted for verified @rice.edu email addresses.'), findsOneWidget);
    });
  });

  group('AuthView Security & Dev Mode Bypass Tests (R3)', () {
    late InMemoryAuthSessionStorage sessionStorage;

    setUp(() {
      sessionStorage = InMemoryAuthSessionStorage();
    });

    testWidgets('renders Bypass Auth (Dev Mode) button when isDevMode is true in debug', (tester) async {
      setDesktopViewport(tester);
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      expect(controller.isDevMode, isTrue);

      await tester.pumpWidget(createTestApp(AuthView(authController: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Bypass Auth (Dev Mode)'), findsOneWidget);
    });

    testWidgets('DOES NOT render Bypass Auth (Dev Mode) when isDevMode is false (production simulation)', (tester) async {
      setDesktopViewport(tester);
      final authService = MockProductionAuthService();
      final controller = AuthController(authService: authService);

      expect(controller.isDevMode, isFalse);

      await tester.pumpWidget(createTestApp(AuthView(authController: controller)));
      await tester.pumpAndSettle();

      // Strict production guarantee: The button is completely absent from widget tree
      expect(find.text('Bypass Auth (Dev Mode)'), findsNothing);
    });

    testWidgets('tapping Bypass Auth (Dev Mode) signs in as Sammy the Owl', (tester) async {
      setDesktopViewport(tester);
      final authService = AuthService(sessionStorage: sessionStorage);
      final controller = AuthController(authService: authService);

      await tester.pumpWidget(createTestApp(AuthView(authController: controller)));
      await tester.pumpAndSettle();

      final bypassButton = find.text('Bypass Auth (Dev Mode)');
      await tester.ensureVisible(bypassButton);
      await tester.tap(bypassButton);
      await tester.pumpAndSettle();

      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser!.email, equals('sammy.owl@rice.edu'));
    });
  });
}
