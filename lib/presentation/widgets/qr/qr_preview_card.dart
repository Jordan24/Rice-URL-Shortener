import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/constants/rice_logos.dart';
import '../../../core/utils/qr_drawing_helper.dart';
import '../../../data/models/qr_config.dart';

class QrPreviewCard extends StatelessWidget {
  final String url;
  final QrConfig qrConfig;
  final double size;

  const QrPreviewCard({
    super.key,
    required this.url,
    required this.qrConfig,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final qrData = url.isNotEmpty ? url : "https://rice.edu";
    final qrCode = QrCode.fromData(
      data: qrData,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );
    final qrImage = QrImage(qrCode);
    final moduleCount = qrImage.moduleCount;

    final centerStart = (moduleCount * 0.38).floor();
    final centerEnd = (moduleCount * 0.62).ceil();
    final hasLogo = qrConfig.logoType != RiceLogoType.none;

    final logoModules = (centerEnd - centerStart + 1).toDouble();
    final logoSize = (logoModules / moduleCount) * size;
    final assetPath = RiceLogos.getAssetPath(qrConfig.logoType);

    return Center(
      child: Container(
        width: size + 24,
        height: size + 24,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: qrConfig.isBgTransparent ? Colors.transparent : qrConfig.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RiceColors.borderLight, width: 1),
          boxShadow: qrConfig.isBgTransparent
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _QrCustomPainter(
                data: qrData,
                config: qrConfig,
              ),
            ),
            if (hasLogo && assetPath != null)
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(logoSize * 0.16),
                  border: Border.all(
                    color: qrConfig.fgColor.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                padding: EdgeInsets.all(logoSize * 0.1),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QrCustomPainter extends CustomPainter {
  final String data;
  final QrConfig config;

  _QrCustomPainter({required this.data, required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );
    final qrImage = QrImage(qrCode);
    final moduleCount = qrImage.moduleCount;
    final scale = size.width / moduleCount;

    final fgPaint = Paint()
      ..color = config.fgColor
      ..style = PaintingStyle.fill;

    final centerStart = (moduleCount * 0.38).floor();
    final centerEnd = (moduleCount * 0.62).ceil();
    final hasLogo = config.logoType != RiceLogoType.none;
    bool isLogoArea(int x, int y) => hasLogo && x >= centerStart && x <= centerEnd && y >= centerStart && y <= centerEnd;

    // 1. Draw Position Detection Eyes
    QrDrawingHelper.drawFinderEyes(canvas, moduleCount, scale, config.style, fgPaint);

    // 2. Draw Alignment Patterns
    final alignmentCenters = QrDrawingHelper.getAlignmentCenters(moduleCount);
    QrDrawingHelper.drawAlignmentPatterns(canvas, alignmentCenters, scale, config.style, fgPaint, isLogoArea);

    // 3. Draw Data Modules
    for (int y = 0; y < moduleCount; y++) {
      for (int x = 0; x < moduleCount; x++) {
        if (QrDrawingHelper.isFinderPattern(x, y, moduleCount) || isLogoArea(x, y)) {
          continue;
        }
        if (config.style == QrStyle.dots && QrDrawingHelper.isInsideAlignmentPattern(x, y, alignmentCenters)) {
          continue;
        }

        if (qrImage.isDark(y, x)) {
          QrDrawingHelper.drawDataModule(
            canvas,
            x,
            y,
            scale,
            config.style,
            qrImage,
            moduleCount,
            fgPaint,
            isLogoArea,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCustomPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.config.fgColorHex != config.fgColorHex ||
        oldDelegate.config.bgColorHex != config.bgColorHex ||
        oldDelegate.config.style != config.style ||
        oldDelegate.config.logoType != config.logoType;
  }
}
