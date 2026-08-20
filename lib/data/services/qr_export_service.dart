import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import '../../core/constants/rice_colors.dart';
import '../../core/constants/rice_logos.dart';
import '../../core/utils/qr_drawing_helper.dart';
import '../../core/utils/web_download_helper.dart';
import '../models/qr_config.dart';

class QrExportService {
  QrExportService._();

  static const int defaultQuietZone = 4;

  /// Generates a scalable SVG string representation of the QR code with quiet zone padding
  static String generateSvg(String data, QrConfig config, {int size = 512, int quietZone = defaultQuietZone}) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );
    final qrImage = QrImage(qrCode);
    final moduleCount = qrImage.moduleCount;
    final totalModules = moduleCount + (quietZone * 2);

    final fgColorHex = config.fgColorHex.startsWith("#") ? config.fgColorHex : "#${config.fgColorHex}";
    final isTransparent = config.isBgTransparent;
    final bgColorHex = isTransparent ? "none" : (config.bgColorHex.startsWith("#") ? config.bgColorHex : "#${config.bgColorHex}");

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $totalModules $totalModules" width="$size" height="$size">');

    // Background covering full image including quiet zone
    if (!isTransparent) {
      buffer.writeln('  <rect width="$totalModules" height="$totalModules" fill="$bgColorHex"/>');
    }

    final centerStart = (moduleCount * 0.38).floor();
    final centerEnd = (moduleCount * 0.62).ceil();
    final hasLogo = config.logoType != RiceLogoType.none;
    bool isLogoArea(int x, int y) => hasLogo && x >= centerStart && x <= centerEnd && y >= centerStart && y <= centerEnd;

    final alignmentCenters = QrDrawingHelper.getAlignmentCenters(moduleCount);

    if (quietZone > 0) {
      buffer.writeln('  <g transform="translate($quietZone, $quietZone)">');
    }

    // Build Eyes, Alignment patterns, and Data modules
    QrDrawingHelper.buildSvgContent(
      buffer: buffer,
      qrImage: qrImage,
      moduleCount: moduleCount,
      style: config.style,
      fgColorHex: fgColorHex,
      isLogoArea: isLogoArea,
      alignmentCenters: alignmentCenters,
    );

    // Quiet zone cutout and Center Logo
    if (hasLogo) {
      final logoWidth = centerEnd - centerStart + 1;
      final logoOffset = centerStart.toDouble();

      // Quiet zone background
      buffer.writeln('  <rect x="$logoOffset" y="$logoOffset" width="$logoWidth" height="$logoWidth" rx="1.5" fill="white"/>');

      String logoSvgContent = "";
      switch (config.logoType) {
        case RiceLogoType.shield:
          logoSvgContent = RiceLogos.shieldSvg;
          break;
        case RiceLogoType.owl:
          logoSvgContent = RiceLogos.owlSvg;
          break;
        case RiceLogoType.oldEnglishR:
          logoSvgContent = RiceLogos.oldEnglishRSvg;
          break;
        case RiceLogoType.none:
          break;
      }

      if (logoSvgContent.isNotEmpty) {
        buffer.writeln('  <g transform="translate(${logoOffset + 0.5}, ${logoOffset + 0.5}) scale(${(logoWidth - 1) / 100})">');
        buffer.writeln(logoSvgContent);
        buffer.writeln('  </g>');
      }
    }

    if (quietZone > 0) {
      buffer.writeln('  </g>');
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  /// Renders and rasterizes a high-resolution PNG using Flutter Canvas with quiet zone padding
  static Future<Uint8List> generatePngBytes(String data, QrConfig config, int targetPixelSize, {int quietZone = defaultQuietZone}) async {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );
    final qrImage = QrImage(qrCode);
    final moduleCount = qrImage.moduleCount;
    final totalModules = moduleCount + (quietZone * 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, targetPixelSize.toDouble(), targetPixelSize.toDouble()));
    final scale = targetPixelSize / totalModules;

    // Background covering full image including quiet zone
    if (!config.isBgTransparent) {
      final bgPaint = Paint()..color = config.bgColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, targetPixelSize.toDouble(), targetPixelSize.toDouble()), bgPaint);
    }

    canvas.save();
    if (quietZone > 0) {
      canvas.translate(quietZone * scale, quietZone * scale);
    }

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

    // Logo Quiet Zone & Drawing
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
        ..strokeWidth = 2;
      canvas.drawRRect(RRect.fromRectAndRadius(logoRect, Radius.circular(scale * 1.5)), quietBorder);

      // Draw vector logo marks
      _drawLogoOnCanvas(canvas, logoRect.deflate(scale * 0.8), config.logoType);
    }

    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(targetPixelSize, targetPixelSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  static void _drawLogoOnCanvas(Canvas canvas, Rect bounds, RiceLogoType logoType) {
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
        
        // Owl eyes
        final eyeRadius = bounds.width * 0.18;
        final leftEyeCenter = Offset(center.dx - bounds.width * 0.16, center.dy - bounds.height * 0.1);
        final rightEyeCenter = Offset(center.dx + bounds.width * 0.16, center.dy - bounds.height * 0.1);
        
        canvas.drawCircle(leftEyeCenter, eyeRadius, owlEye);
        canvas.drawCircle(rightEyeCenter, eyeRadius, owlEye);
        canvas.drawCircle(leftEyeCenter, eyeRadius * 0.6, pupil);
        canvas.drawCircle(rightEyeCenter, eyeRadius * 0.6, pupil);

        // Beak
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

  /// Triggers browser download for SVG
  static void exportSvg(String data, QrConfig config, String shortCode) {
    final svgString = generateSvg(data, config);
    WebDownloadHelper.downloadString(svgString, "rice_qr_$shortCode.svg", "image/svg+xml");
  }

  /// Triggers browser download for PNG
  static Future<void> exportPng(String data, QrConfig config, String shortCode, int size) async {
    final bytes = await generatePngBytes(data, config, size);
    WebDownloadHelper.downloadBytes(bytes, "rice_qr_${shortCode}_${size}px.png", "image/png");
  }
}
