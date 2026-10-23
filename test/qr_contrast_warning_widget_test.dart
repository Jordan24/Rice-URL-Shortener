import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rice_url_shortener/presentation/widgets/qr/qr_color_selector.dart';
import 'package:rice_url_shortener/presentation/widgets/qr/qr_contrast_warning.dart';

void main() {
  group('QrContrastWarning Widget Tests', () {
    testWidgets('Renders nothing when colors meet QR standards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QrContrastWarning(
              fgColorHex: '#00205B', // Rice Blue
              bgColorHex: '#FFFFFF', // White
            ),
          ),
        ),
      );

      // Warning shouldn't display any alert texts or warning icons
      expect(find.byType(QrContrastWarning), findsOneWidget);
      expect(find.textContaining('Warning'), findsNothing);
      expect(find.textContaining('Contrast'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('Renders warning banner for low contrast colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QrContrastWarning(
              fgColorHex: '#4D9AD4', // Medium Blue (~3.05:1 on White)
              bgColorHex: '#FFFFFF',
            ),
          ),
        ),
      );

      expect(find.text('Low Contrast Warning'), findsOneWidget);
      expect(find.text('3.0:1 (Min 4.0:1)'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('recommended 4.0:1 standard'), findsOneWidget);
    });

    testWidgets('Renders critical banner for critically low contrast', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QrContrastWarning(
              fgColorHex: '#4D9AD4', // Medium Blue on Light Blue Gray (~1.74:1)
              bgColorHex: '#ADC7DC',
            ),
          ),
        ),
      );

      expect(find.text('Critically Low Contrast'), findsOneWidget);
      expect(find.text('1.7:1 (Min 4.0:1)'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('Renders inverted contrast warning when foreground is lighter than background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QrContrastWarning(
              fgColorHex: '#FFFFFF', // White on Rice Blue
              bgColorHex: '#00205B',
            ),
          ),
        ),
      );

      expect(find.text('Inverted Contrast (Light on Dark)'), findsOneWidget);
      expect(find.text('Inverted'), findsOneWidget);
      expect(find.textContaining('ISO/IEC 18004'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('Renders warning for light foreground on transparent background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QrContrastWarning(
              fgColorHex: '#9FDDF9', // Bright Blue on Transparent
              bgColorHex: '#00000000',
            ),
          ),
        ),
      );

      expect(find.text('Light Foreground on Transparent'), findsOneWidget);
      expect(find.text('Transparent BG'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });

  group('QrColorSelector Contrast Integration Tests', () {
    testWidgets('Displays real-time warning when low-contrast color is selected', (tester) async {
      String fg = '#00205B';
      String bg = '#FFFFFF';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return QrColorSelector(
                  fgColorHex: fg,
                  bgColorHex: bg,
                  onFgColorChanged: (newFg) => setState(() => fg = newFg),
                  onBgColorChanged: (newBg) => setState(() => bg = newBg),
                );
              },
            ),
          ),
        ),
      );

      // Initially compliant: no warning
      expect(find.textContaining('Low Contrast Warning'), findsNothing);
      expect(find.textContaining('Critically Low Contrast'), findsNothing);

      // Tap 'Medium Blue' foreground preset (#4D9AD4)
      final mediumBluePreset = find.byTooltip('Medium Blue');
      expect(mediumBluePreset, findsWidgets); // May appear in FG and BG
      await tester.tap(mediumBluePreset.first);
      await tester.pumpAndSettle();

      // Now FG is Medium Blue on White -> Low Contrast Warning should be visible!
      expect(find.text('Low Contrast Warning'), findsOneWidget);
      expect(find.text('3.0:1 (Min 4.0:1)'), findsOneWidget);

      // Tap 'Rice Blue' foreground preset to restore high contrast
      final riceBluePreset = find.byTooltip('Rice Blue');
      await tester.tap(riceBluePreset);
      await tester.pumpAndSettle();

      // Warning disappears
      expect(find.text('Low Contrast Warning'), findsNothing);
    });
  });
}
