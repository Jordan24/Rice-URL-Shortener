import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import '../../core/constants/rice_logos.dart';
import '../../core/utils/qr_drawing_helper.dart';
import '../../core/utils/web_download_helper.dart';
import '../models/qr_config.dart';

class QrExportService {
  QrExportService._();

  static const int defaultQuietZone = 4;

  /// Generates a scalable SVG string representation of the QR code with quiet zone padding
  static String generateSvg(
    String data,
    QrConfig config, {
    int size = 512,
    int quietZone = defaultQuietZone,
    String? logoBase64,
  }) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );
    final qrImage = QrImage(qrCode);
    final moduleCount = qrImage.moduleCount;
    final totalModules = moduleCount + (quietZone * 2);

    final fgColorHex = config.fgColorHex.startsWith("#") ? config.fgColorHex : "#${config.fgColorHex}";
    final bgColorHex = config.isBgTransparent
        ? "none"
        : (config.bgColorHex.startsWith("#") ? config.bgColorHex : "#${config.bgColorHex}");

    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $totalModules $totalModules" width="$size" height="$size">');

    if (!config.isBgTransparent) {
      buffer.writeln('  <rect width="$totalModules" height="$totalModules" fill="$bgColorHex"/>');
    }

    final cutout = QrDrawingHelper.getLogoCutoutRange(moduleCount);
    final hasLogo = config.logoType != RiceLogoType.none;
    bool isLogoArea(int x, int y) => QrDrawingHelper.isLogoArea(x, y, moduleCount, hasLogo);

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

    // Center Logo (transparent background so QR background shows through, foreground-colored SVG path)
    if (hasLogo) {
      final logoWidth = (cutout.end - cutout.start + 1).toDouble();
      final logoOffset = cutout.start.toDouble();

      final base64Png = logoBase64;
      if (base64Png != null && base64Png.isNotEmpty) {
        buffer.writeln('  <image href="data:image/png;base64,$base64Png" x="$logoOffset" y="$logoOffset" width="$logoWidth" height="$logoWidth" preserveAspectRatio="xMidYMid meet"/>');
      } else {
        final svgPath = RiceLogos.getSvgPathData(config.logoType);
        if (svgPath != null && svgPath.isNotEmpty) {
          buffer.writeln('  <svg x="$logoOffset" y="$logoOffset" width="$logoWidth" height="$logoWidth" viewBox="0 0 512 512" preserveAspectRatio="xMidYMid meet">');
          buffer.writeln('    <path fill="$fgColorHex" fill-rule="evenodd" d="$svgPath"/>');
          buffer.writeln('  </svg>');
        }
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

    final cutout = QrDrawingHelper.getLogoCutoutRange(moduleCount);
    final hasLogo = config.logoType != RiceLogoType.none;
    bool isLogoArea(int x, int y) => QrDrawingHelper.isLogoArea(x, y, moduleCount, hasLogo);

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

    // Center Logo drawing (transparent background, tinted to foreground color)
    if (hasLogo) {
      final logoRect = Rect.fromLTRB(
        cutout.start * scale,
        cutout.start * scale,
        (cutout.end + 1) * scale,
        (cutout.end + 1) * scale,
      );

      final uiImage = await RiceLogos.getUiImage(config.logoType);
      if (uiImage != null) {
        final srcRect = Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble());
        final imagePaint = Paint()..filterQuality = FilterQuality.high;
        if (config.logoType.isUniversityMark) {
          imagePaint.colorFilter = ColorFilter.mode(config.fgColor, BlendMode.srcIn);
        }
        canvas.drawImageRect(uiImage, srcRect, logoRect, imagePaint);
      }
    }

    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(targetPixelSize, targetPixelSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// Triggers browser download for SVG
  static Future<void> exportSvg(String data, QrConfig config, String shortCode) async {
    final base64Png = config.logoType.isUniversityMark ? null : await RiceLogos.getBase64Png(config.logoType);
    final svgString = generateSvg(data, config, logoBase64: base64Png);
    WebDownloadHelper.downloadString(svgString, "rice_qr_$shortCode.svg", "image/svg+xml");
  }

  /// Triggers browser download for PNG
  static Future<void> exportPng(String data, QrConfig config, String shortCode, int size) async {
    final bytes = await generatePngBytes(data, config, size);
    WebDownloadHelper.downloadBytes(bytes, "rice_qr_${shortCode}_${size}px.png", "image/png");
  }
}
