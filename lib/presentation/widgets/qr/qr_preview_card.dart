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
        child: CustomPaint(
          size: Size(size, size),
          painter: _QrCustomPainter(
            data: qrData,
            config: qrConfig,
          ),
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

    // Draw Quiet Zone & Logo
    if (hasLogo) {
      final logoRect = Rect.fromLTRB(
        centerStart * scale,
        centerStart * scale,
        (centerEnd + 1) * scale,
        (centerEnd + 1) * scale,
      );

      final quietPaint = Paint()..color = Colors.white;
      canvas.drawRRect(RRect.fromRectAndRadius(logoRect, Radius.circular(scale * 1.5)), quietPaint);

      final quietBorder = Paint()
        ..color = config.fgColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(RRect.fromRectAndRadius(logoRect, Radius.circular(scale * 1.5)), quietBorder);

      _drawLogo(canvas, logoRect.deflate(scale * 0.7), config.logoType);
    }
  }

  void _drawLogo(Canvas canvas, Rect bounds, RiceLogoType logoType) {
    final center = bounds.center;
    final radius = bounds.width / 2;

    switch (logoType) {
      case RiceLogoType.shield:
        final shieldPaint = Paint()..color = RiceColors.riceBlue;
        final goldPaint = Paint()..color = RiceColors.laurelGold;
        final whitePaint = Paint()..color = Colors.white;

        final path = Path()
          ..moveTo(bounds.left + bounds.width * 0.15, bounds.top + bounds.height * 0.1)
          ..lineTo(bounds.right - bounds.width * 0.15, bounds.top + bounds.height * 0.1)
          ..lineTo(bounds.right - bounds.width * 0.15, bounds.top + bounds.height * 0.55)
          ..cubicTo(
            bounds.right - bounds.width * 0.15,
            bounds.bottom - bounds.height * 0.1,
            center.dx,
            bounds.bottom,
            center.dx,
            bounds.bottom,
          )
          ..cubicTo(
            center.dx,
            bounds.bottom,
            bounds.left + bounds.width * 0.15,
            bounds.bottom - bounds.height * 0.1,
            bounds.left + bounds.width * 0.15,
            bounds.top + bounds.height * 0.55,
          )
          ..close();

        canvas.drawPath(path, shieldPaint);
        canvas.drawCircle(Offset(center.dx - bounds.width * 0.15, bounds.top + bounds.height * 0.35), bounds.width * 0.08, whitePaint);
        canvas.drawCircle(Offset(center.dx + bounds.width * 0.15, bounds.top + bounds.height * 0.35), bounds.width * 0.08, whitePaint);

        final chevron = Path()
          ..moveTo(center.dx - bounds.width * 0.18, bounds.top + bounds.height * 0.65)
          ..lineTo(center.dx, bounds.top + bounds.height * 0.52)
          ..lineTo(center.dx + bounds.width * 0.18, bounds.top + bounds.height * 0.65)
          ..lineTo(center.dx, bounds.top + bounds.height * 0.78)
          ..close();
        canvas.drawPath(chevron, goldPaint);
        break;

      case RiceLogoType.owl:
        final owlBody = Paint()..color = RiceColors.riceBlue;
        final owlEye = Paint()..color = Colors.white;
        final pupil = Paint()..color = RiceColors.riceBlue;
        final beak = Paint()..color = RiceColors.laurelGold;

        canvas.drawOval(bounds.deflate(bounds.width * 0.08), owlBody);

        final eyeRadius = bounds.width * 0.18;
        final leftEyeCenter = Offset(center.dx - bounds.width * 0.16, center.dy - bounds.height * 0.1);
        final rightEyeCenter = Offset(center.dx + bounds.width * 0.16, center.dy - bounds.height * 0.1);

        canvas.drawCircle(leftEyeCenter, eyeRadius, owlEye);
        canvas.drawCircle(rightEyeCenter, eyeRadius, owlEye);
        canvas.drawCircle(leftEyeCenter, eyeRadius * 0.6, pupil);
        canvas.drawCircle(rightEyeCenter, eyeRadius * 0.6, pupil);

        final beakPath = Path()
          ..moveTo(center.dx, center.dy - bounds.height * 0.05)
          ..lineTo(center.dx - bounds.width * 0.08, center.dy + bounds.height * 0.1)
          ..lineTo(center.dx + bounds.width * 0.08, center.dy + bounds.height * 0.1)
          ..close();
        canvas.drawPath(beakPath, beak);
        break;

      case RiceLogoType.oldEnglishR:
        final rCircle = Paint()..color = RiceColors.riceBlue;
        canvas.drawCircle(center, radius * 0.92, rCircle);

        final textPainter = TextPainter(
          text: TextSpan(
            text: "R",
            style: TextStyle(
              color: Colors.white,
              fontSize: bounds.height * 0.65,
              fontWeight: FontWeight.w900,
              fontFamily: "Georgia",
              fontStyle: FontStyle.italic,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
        break;

      case RiceLogoType.none:
        break;
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
