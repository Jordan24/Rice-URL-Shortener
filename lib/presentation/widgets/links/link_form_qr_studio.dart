import 'package:flutter/material.dart';
import '../../../core/constants/branding_colors.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/constants/rice_logos.dart';
import '../../../core/theme/rice_theme.dart';
import '../../../data/models/qr_config.dart';
import '../qr/qr_branding_selector.dart';
import '../qr/qr_color_selector.dart';
import '../qr/qr_logo_selector.dart';
import '../qr/qr_preview_card.dart';
import '../qr/qr_style_selector.dart';

class LinkFormQrStudio extends StatelessWidget {
  final String previewUrl;
  final QrConfig qrConfig;
  final ValueChanged<QrConfig> onQrConfigChanged;

  const LinkFormQrStudio({
    super.key,
    required this.previewUrl,
    required this.qrConfig,
    required this.onQrConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "QR Code Studio",
          style: RiceTheme.heading(fontSize: 18, fontWeight: FontWeight.w700, color: RiceColors.riceBlue),
        ),
        const SizedBox(height: 14),

        // Live Preview Card
        QrPreviewCard(
          url: previewUrl,
          qrConfig: qrConfig,
          size: 160,
        ),

        const SizedBox(height: 16),

        // Branding Pack Selector (Rice University & 12 Residential Colleges)
        QrBrandingSelector(
          selectedPack: qrConfig.brandingPack,
          onBrandingPackChanged: (newPack) {
            final defaultFg = BrandingColors.getDefaultFgColorHex(newPack);
            final defaultBg = BrandingColors.getDefaultBgColorHex(newPack);
            final defaultLogo = RiceLogos.getDefaultLogoForPack(newPack);

            onQrConfigChanged(
              qrConfig.copyWith(
                brandingPack: newPack,
                fgColorHex: defaultFg,
                bgColorHex: defaultBg,
                logoType: qrConfig.logoType == RiceLogoType.none ? RiceLogoType.none : defaultLogo,
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // QR Module Style
        QrStyleSelector(
          selectedStyle: qrConfig.style,
          onStyleChanged: (s) => onQrConfigChanged(qrConfig.copyWith(style: s)),
        ),

        const SizedBox(height: 16),

        // QR Colors (Tailored to selected branding pack)
        QrColorSelector(
          fgColorHex: qrConfig.fgColorHex,
          bgColorHex: qrConfig.bgColorHex,
          brandingPack: qrConfig.brandingPack,
          onFgColorChanged: (c) => onQrConfigChanged(qrConfig.copyWith(fgColorHex: c)),
          onBgColorChanged: (c) => onQrConfigChanged(qrConfig.copyWith(bgColorHex: c)),
        ),

        const SizedBox(height: 16),

        // QR Logo (Tailored to selected branding pack)
        QrLogoSelector(
          selectedLogo: qrConfig.logoType,
          brandingPack: qrConfig.brandingPack,
          onLogoChanged: (l) => onQrConfigChanged(qrConfig.copyWith(logoType: l)),
        ),
      ],
    );
  }
}
