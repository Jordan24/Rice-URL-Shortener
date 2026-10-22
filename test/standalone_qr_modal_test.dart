import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rice_url_shortener/data/models/short_link.dart';
import 'package:rice_url_shortener/data/services/auth_service.dart';
import 'package:rice_url_shortener/data/services/link_service.dart';
import 'package:rice_url_shortener/presentation/state/auth_controller.dart';
import 'package:rice_url_shortener/presentation/state/link_controller.dart';
import 'package:rice_url_shortener/presentation/views/dashboard_view.dart';
import 'package:rice_url_shortener/presentation/widgets/qr/qr_preview_card.dart';
import 'package:rice_url_shortener/presentation/widgets/qr/standalone_qr_modal.dart';

class FakeLinkService implements LinkService {
  final List<ShortLink> links = [];

  @override
  Future<bool> isShortCodeAvailable(String code, {String? excludeLinkId}) async => true;

  @override
  Stream<List<ShortLink>> streamUserLinks(String userId) => Stream.value(List.of(links));

  @override
  Future<ShortLink> createLink(ShortLink link) async {
    links.add(link);
    return link;
  }

  @override
  Future<void> updateLink(ShortLink link) async {}

  @override
  Future<void> toggleLinkActive(String linkId, bool currentStatus) async {}

  @override
  Future<void> deleteLink(String linkId) async {}

  @override
  void dispose() {}
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
  group('StandaloneQrModal.deriveFileLabel Tests', () {
    test('extracts sanitized host from valid URLs', () {
      expect(StandaloneQrModal.deriveFileLabel('https://rice.edu/admissions'), equals('rice_edu'));
      expect(StandaloneQrModal.deriveFileLabel('https://forms.gle/xyz123'), equals('forms_gle'));
    });

    test('truncates long hostnames to 24 characters', () {
      final label = StandaloneQrModal.deriveFileLabel('https://very-long-subdomain-department.rice.edu/event');
      expect(label.length, lessThanOrEqualTo(24));
    });

    test('falls back to custom when URL has no host', () {
      expect(StandaloneQrModal.deriveFileLabel(''), equals('custom'));
    });
  });

  group('StandaloneQrModal Widget Tests', () {
    testWidgets('renders QR studio controls, non-saved notice, and validates URL before download', (tester) async {
      setDesktopViewport(tester);

      await tester.pumpWidget(
        createTestApp(
          const Scaffold(
            body: StandaloneQrModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Standalone QR Code'), findsOneWidget);
      expect(find.text('Destination Web Address *'), findsOneWidget);
      expect(find.text('QR Code Studio'), findsOneWidget);
      expect(find.textContaining('It is not saved to your account'), findsOneWidget);
      expect(find.text('Download SVG'), findsOneWidget);
      expect(find.text('Download PNG'), findsOneWidget);

      // Attempting to download with empty URL triggers validation error
      await tester.tap(find.text('Download SVG'));
      await tester.pumpAndSettle();

      expect(find.text('Destination URL is required.'), findsOneWidget);

      // Entering a URL updates the live QrPreviewCard and clears error on download
      final urlInput = find.byType(TextFormField);
      await tester.enterText(urlInput, 'rice.edu/commencement');
      await tester.pumpAndSettle();

      final previewCard = tester.widget<QrPreviewCard>(find.byType(QrPreviewCard));
      expect(previewCard.url, equals('https://rice.edu/commencement'));

      // Select Rounded QR style
      await tester.tap(find.text('Rounded'));
      await tester.pumpAndSettle();

      // Trigger SVG download and verify confirmation SnackBar
      await tester.tap(find.text('Download SVG'));
      await tester.pumpAndSettle();

      expect(find.text('Downloaded scalable SVG successfully.'), findsOneWidget);
    });

    testWidgets('DashboardView opens StandaloneQrModal without saving links to user account', (tester) async {
      setDesktopViewport(tester);

      final authService = AuthService(sessionStorage: InMemoryAuthSessionStorage());
      final authController = AuthController(authService: authService);
      await authController.signInAsDev();

      final fakeLinkService = FakeLinkService();
      final linkController = LinkController(linkService: fakeLinkService);

      await tester.pumpWidget(
        createTestApp(
          DashboardView(
            authController: authController,
            linkController: linkController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both header and empty state offer Create QR Code
      expect(find.text('Create QR Code'), findsWidgets);

      await tester.tap(find.text('Create QR Code').first);
      await tester.pumpAndSettle();

      expect(find.byType(StandaloneQrModal), findsOneWidget);
      expect(fakeLinkService.links, isEmpty);
    });
  });
}
