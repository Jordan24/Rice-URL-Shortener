import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rice_url_shortener/core/constants/branding_colors.dart';
import 'package:rice_url_shortener/core/constants/branding_pack.dart';
import 'package:rice_url_shortener/core/constants/rice_logos.dart';
import 'package:rice_url_shortener/data/models/qr_config.dart';
import 'package:rice_url_shortener/data/services/qr_export_service.dart';
import 'package:rice_url_shortener/presentation/widgets/links/link_form_qr_studio.dart';
import 'package:rice_url_shortener/presentation/widgets/qr/qr_branding_selector.dart';

void main() {
  group('BrandingPackType & BrandingColors Model Tests', () {
    test('BrandingPackType contains University and all 12 Residential Colleges in order', () {
      expect(BrandingPackType.values.length, equals(13));
      expect(BrandingPackType.values, equals([
        BrandingPackType.university,
        BrandingPackType.baker,
        BrandingPackType.willRice,
        BrandingPackType.hanszen,
        BrandingPackType.wiess,
        BrandingPackType.jones,
        BrandingPackType.brown,
        BrandingPackType.lovett,
        BrandingPackType.sidRichardson,
        BrandingPackType.martel,
        BrandingPackType.mcmurtry,
        BrandingPackType.duncan,
        BrandingPackType.chao,
      ]));
    });

    test('BrandingPackType.fromString handles case-insensitivity and defaults safely', () {
      expect(BrandingPackType.fromString('baker'), equals(BrandingPackType.baker));
      expect(BrandingPackType.fromString('WILLRICE'), equals(BrandingPackType.willRice));
      expect(BrandingPackType.fromString('chao'), equals(BrandingPackType.chao));
      expect(BrandingPackType.fromString(null), equals(BrandingPackType.university));
      expect(BrandingPackType.fromString('unknown'), equals(BrandingPackType.university));
    });

    test('BrandingColors returns authentic default colors for every college pack', () {
      expect(BrandingColors.getDefaultFgColorHex(BrandingPackType.university), equals('#00205B'));
      expect(BrandingColors.getDefaultFgColorHex(BrandingPackType.baker), equals('#C8102E'));
      expect(BrandingColors.getDefaultFgColorHex(BrandingPackType.willRice), equals('#C03720'));
      expect(BrandingColors.getDefaultFgColorHex(BrandingPackType.hanszen), equals('#0099DD'));
      expect(BrandingColors.getDefaultFgColorHex(BrandingPackType.wiess), equals('#DAA520'));
      expect(BrandingColors.getDefaultFgColorHex(BrandingPackType.jones), equals('#006400'));
      expect(BrandingColors.getDefaultFgColorHex(BrandingPackType.brown), equals('#800020'));
      expect(BrandingColors.getDefaultFgColorHex(BrandingPackType.lovett), equals('#00205B'));
      expect(BrandingColors.getDefaultFgColorHex(BrandingPackType.sidRichardson), equals('#C41230'));
      expect(BrandingColors.getDefaultFgColorHex(BrandingPackType.martel), equals('#0072CE'));
      expect(BrandingColors.getDefaultFgColorHex(BrandingPackType.mcmurtry), equals('#4B2E83'));
      expect(BrandingColors.getDefaultFgColorHex(BrandingPackType.duncan), equals('#00432C'));
      expect(BrandingColors.getDefaultFgColorHex(BrandingPackType.chao), equals('#FF8DA1'));
    });

    test('Every college pack offers its heraldic colors plus generic Black, White, and Transparent', () {
      for (final pack in BrandingPackType.values) {
        final fgPresets = BrandingColors.getFgPresets(pack);
        final bgPresets = BrandingColors.getBgPresets(pack);

        expect(fgPresets.any((p) => p.hex.toLowerCase() == '#000000'), isTrue,
            reason: '${pack.label} missing generic black in FG');
        expect(bgPresets.any((p) => p.hex.toLowerCase() == '#ffffff'), isTrue,
            reason: '${pack.label} missing generic white in BG');
        expect(bgPresets.any((p) => p.hex.toLowerCase() == '#00000000'), isTrue,
            reason: '${pack.label} missing transparent in BG');
      }
    });

    test('RiceLogos provides tailored logos for each pack', () {
      // University branding offers Owl, Old English R, and None
      expect(
        RiceLogos.getLogosForPack(BrandingPackType.university),
        equals([RiceLogoType.owl, RiceLogoType.oldEnglishR, RiceLogoType.none]),
      );

      // Baker offers Baker Shield and None
      expect(
        RiceLogos.getLogosForPack(BrandingPackType.baker),
        equals([RiceLogoType.baker, RiceLogoType.none]),
      );

      // Will Rice offers Will Rice Phoenix and None
      expect(
        RiceLogos.getLogosForPack(BrandingPackType.willRice),
        equals([RiceLogoType.willRice, RiceLogoType.none]),
      );

      // Chao offers Chao Crest and None
      expect(
        RiceLogos.getLogosForPack(BrandingPackType.chao),
        equals([RiceLogoType.chao, RiceLogoType.none]),
      );
    });

    test('RiceLogos.getSelectorLogoForPack and getSelectorAssetPath return Old English R for university and college crests for colleges', () {
      expect(RiceLogos.getSelectorLogoForPack(BrandingPackType.university), equals(RiceLogoType.oldEnglishR));
      expect(RiceLogos.getSelectorAssetPath(BrandingPackType.university), equals('assets/logos/rice_r.png'));

      for (final pack in BrandingPackType.values.where((p) => p != BrandingPackType.university)) {
        final expectedLogo = RiceLogos.getDefaultLogoForPack(pack);
        expect(RiceLogos.getSelectorLogoForPack(pack), equals(expectedLogo));
        expect(RiceLogos.getSelectorAssetPath(pack), equals(RiceLogos.getAssetPath(expectedLogo)));
        expect(RiceLogos.getSelectorAssetPath(pack), isNotNull);
      }
    });

    test('QrConfig serializes and deserializes brandingPack with full backward compatibility', () {
      const config = QrConfig(
        brandingPack: BrandingPackType.martel,
        logoType: RiceLogoType.martel,
        fgColorHex: '#0072CE',
      );

      final map = config.toMap();
      expect(map['brandingPack'], equals('martel'));
      expect(map['logoType'], equals('martel'));

      final restored = QrConfig.fromMap(map);
      expect(restored.brandingPack, equals(BrandingPackType.martel));
      expect(restored.logoType, equals(RiceLogoType.martel));

      // Legacy map without brandingPack field
      final legacyMap = {
        'fgColorHex': '#00205B',
        'bgColorHex': '#FFFFFF',
        'style': 'square',
        'logoType': 'owl',
      };
      final restoredLegacy = QrConfig.fromMap(legacyMap);
      expect(restoredLegacy.brandingPack, equals(BrandingPackType.university));
    });
  });

  group('SVG Export with College Branding', () {
    test('SVG export generates valid SVG with college crest and foreground color', () {
      for (final pack in BrandingPackType.values.where((p) => p != BrandingPackType.university)) {
        final logo = RiceLogos.getDefaultLogoForPack(pack);
        final fgHex = BrandingColors.getDefaultFgColorHex(pack);

        final config = QrConfig(
          brandingPack: pack,
          logoType: logo,
          fgColorHex: fgHex,
          bgColorHex: '#FFFFFF',
        );

        final svg = QrExportService.generateSvg('https://go.thejambers.com/test-${pack.name}', config);
        expect(svg, contains('<path fill="$fgHex" fill-rule="evenodd" d="M '));
        expect(svg, isNot(contains('fill="white"')));
      }
    });
  });

  group('Branding Pack Widget Integration Tests', () {
    testWidgets('QrBrandingSelector renders and triggers selection callback', (tester) async {
      BrandingPackType selected = BrandingPackType.university;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return QrBrandingSelector(
                  selectedPack: selected,
                  onBrandingPackChanged: (p) => setState(() => selected = p),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Branding Pack'), findsOneWidget);
      expect(find.text('Rice University'), findsOneWidget);

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<BrandingPackType>));
      await tester.pumpAndSettle();

      // Verify colors on the right are removed
      expect(find.text('Institutional'), findsNothing);
      expect(find.text('Red & Silver'), findsNothing);
      expect(find.text('Rust & Gold'), findsNothing);

      // Tap Baker College
      final bakerItem = find.text('Baker College').last;
      await tester.tap(bakerItem);
      await tester.pumpAndSettle();

      expect(selected, equals(BrandingPackType.baker));
    });

    testWidgets('LinkFormQrStudio switches college pack, updates colors, and swaps logo options', (tester) async {
      QrConfig config = const QrConfig();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: LinkFormQrStudio(
                    previewUrl: 'https://rice.edu',
                    qrConfig: config,
                    onQrConfigChanged: (c) => setState(() => config = c),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initially University branding
      expect(find.text('Center Rice University Logo'), findsOneWidget);
      expect(find.text('Rice Owl'), findsOneWidget);
      expect(find.text('Old English R'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);

      // Switch to Baker College
      await tester.tap(find.byType(DropdownButton<BrandingPackType>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Baker College').last);
      await tester.pumpAndSettle();

      // State is updated to Baker College defaults
      expect(config.brandingPack, equals(BrandingPackType.baker));
      expect(config.fgColorHex, equals('#C8102E'));
      expect(config.logoType, equals(RiceLogoType.baker));

      // Logo selector now shows Baker Shield and None (Rice Owl & Old English R are replaced!)
      expect(find.text('Center Baker Crest / Logo'), findsOneWidget);
      expect(find.text('Baker Shield'), findsOneWidget);
      expect(find.text('Rice Owl'), findsNothing);
      expect(find.text('Old English R'), findsNothing);
      expect(find.text('None'), findsOneWidget);

      // Switch to Will Rice College
      await tester.tap(find.byType(DropdownButton<BrandingPackType>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Will Rice College').last);
      await tester.pumpAndSettle();

      // State is updated to Will Rice College
      expect(config.brandingPack, equals(BrandingPackType.willRice));
      expect(config.fgColorHex, equals('#C03720'));
      expect(config.logoType, equals(RiceLogoType.willRice));
      expect(find.text('Center Will Rice Crest / Logo'), findsOneWidget);
      expect(find.text('Will Rice Phoenix'), findsOneWidget);
    });
  });
}
