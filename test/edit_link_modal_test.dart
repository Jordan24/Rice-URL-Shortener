import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rice_url_shortener/data/models/qr_config.dart';
import 'package:rice_url_shortener/data/models/short_link.dart';
import 'package:rice_url_shortener/data/services/link_service.dart';
import 'package:rice_url_shortener/presentation/state/link_controller.dart';
import 'package:rice_url_shortener/presentation/widgets/links/edit_link_modal.dart';
import 'package:rice_url_shortener/presentation/widgets/links/link_form_qr_studio.dart';

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

Widget createTestApp(Widget child, {Size size = const Size(1440, 900)}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: child,
    ),
  );
}

void setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  final testLink = ShortLink(
    id: 'link123',
    userId: 'user1',
    userEmail: 'student@rice.edu',
    shortCode: 'owlfest',
    destinationUrl: 'https://rice.edu/owlfest',
    fallbackUrl: 'https://rice.edu',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    qrConfig: const QrConfig(),
  );

  group('EditLinkModal Scrollbar Layout Tests', () {
    testWidgets('Scrollbar and content do not overlap in two-column mode', (tester) async {
      setViewport(tester, const Size(1440, 900));

      final fakeService = FakeLinkService();
      final linkController = LinkController(linkService: fakeService);

      await tester.pumpWidget(
        createTestApp(
          Scaffold(
            body: EditLinkModal(
              link: testLink,
              linkController: linkController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title is rendered
      expect(find.text('Edit Short Link & QR Code'), findsOneWidget);

      // Verify Scrollbar widget wraps SingleChildScrollView
      final scrollbarFinder = find.byType(Scrollbar);
      expect(scrollbarFinder, findsOneWidget);

      final singleChildFinder = find.byType(SingleChildScrollView);
      expect(singleChildFinder, findsOneWidget);

      // Verify SingleChildScrollView has right padding configured
      final singleChildScrollView = tester.widget<SingleChildScrollView>(singleChildFinder);
      expect(singleChildScrollView.padding, isNotNull);
      final padding = singleChildScrollView.padding as EdgeInsets;
      expect(padding.right, greaterThanOrEqualTo(16.0));

      // Verify Scrollbar and SingleChildScrollView share the exact same ScrollController
      final scrollbar = tester.widget<Scrollbar>(scrollbarFinder);
      expect(scrollbar.controller, isNotNull);
      expect(singleChildScrollView.controller, equals(scrollbar.controller));

      // Verify physical layout: LinkFormQrStudio on the right must be inset from the
      // right edge of the scroll view by at least the padding amount (>= 16px)
      final scrollViewRect = tester.getRect(singleChildFinder);
      final qrStudioRect = tester.getRect(find.byType(LinkFormQrStudio));

      final rightGap = scrollViewRect.right - qrStudioRect.right;
      expect(rightGap, greaterThanOrEqualTo(16.0),
          reason: 'QR studio content must leave at least 16px clearance for the scrollbar.');
    });

    testWidgets('Scrollbar and content do not overlap in narrow single-column mode', (tester) async {
      setViewport(tester, const Size(500, 800));

      final fakeService = FakeLinkService();
      final linkController = LinkController(linkService: fakeService);

      await tester.pumpWidget(
        createTestApp(
          Scaffold(
            body: EditLinkModal(
              link: testLink,
              linkController: linkController,
            ),
          ),
          size: const Size(500, 800),
        ),
      );
      await tester.pumpAndSettle();

      final singleChildFinder = find.byType(SingleChildScrollView);
      final scrollViewRect = tester.getRect(singleChildFinder);
      final qrStudioRect = tester.getRect(find.byType(LinkFormQrStudio));

      final rightGap = scrollViewRect.right - qrStudioRect.right;
      expect(rightGap, greaterThanOrEqualTo(16.0),
          reason: 'In single-column mode, content must also maintain clearance from the right scrollbar.');
    });
  });
}
