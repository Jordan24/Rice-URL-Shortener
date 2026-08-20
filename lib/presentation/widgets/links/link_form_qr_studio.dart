import 'package:flutter/material.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../data/models/qr_config.dart';
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
        const Text(
          "QR Code Studio",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: RiceColors.textPrimary),
        ),
        const SizedBox(height: 14),

        // Live Preview Card
        QrPreviewCard(
          url: previewUrl,
          qrConfig: qrConfig,
          size: 160,
        ),

        const SizedBox(height: 16),

        // QR Module Style
        QrStyleSelector(
          selectedStyle: qrConfig.style,
          onStyleChanged: (s) => onQrConfigChanged(qrConfig.copyWith(style: s)),
        ),

        const SizedBox(height: 16),

        // QR Colors
        QrColorSelector(
          fgColorHex: qrConfig.fgColorHex,
          bgColorHex: qrConfig.bgColorHex,
          onFgColorChanged: (c) => onQrConfigChanged(qrConfig.copyWith(fgColorHex: c)),
          onBgColorChanged: (c) => onQrConfigChanged(qrConfig.copyWith(bgColorHex: c)),
        ),

        const SizedBox(height: 16),

        // QR Logo
        QrLogoSelector(
          selectedLogo: qrConfig.logoType,
          onLogoChanged: (l) => onQrConfigChanged(qrConfig.copyWith(logoType: l)),
        ),
      ],
    );
  }
}
