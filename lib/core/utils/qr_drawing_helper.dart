import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import '../../data/models/qr_config.dart';

/// Alignment pattern coordinates table per QR version (2 to 40)
const Map<int, List<int>> qrAlignmentLocations = {
  2: [6, 18],
  3: [6, 22],
  4: [6, 26],
  5: [6, 30],
  6: [6, 34],
  7: [6, 22, 38],
  8: [6, 24, 42],
  9: [6, 26, 46],
  10: [6, 28, 50],
  11: [6, 30, 54],
  12: [6, 32, 58],
  13: [6, 34, 62],
  14: [6, 26, 46, 66],
  15: [6, 26, 48, 70],
  16: [6, 26, 50, 74],
  17: [6, 30, 54, 78],
  18: [6, 30, 56, 82],
  19: [6, 30, 58, 86],
  20: [6, 34, 62, 90],
  21: [6, 28, 50, 72, 94],
  22: [6, 26, 50, 74, 98],
  23: [6, 30, 54, 78, 102],
  24: [6, 28, 54, 80, 106],
  25: [6, 32, 58, 84, 110],
  26: [6, 30, 58, 86, 114],
  27: [6, 34, 62, 90, 118],
  28: [6, 26, 50, 74, 98, 122],
  29: [6, 30, 54, 78, 102, 126],
  30: [6, 26, 52, 78, 104, 130],
  31: [6, 30, 56, 82, 108, 134],
  32: [6, 34, 60, 86, 112, 138],
  33: [6, 30, 58, 86, 114, 142],
  34: [6, 34, 62, 90, 118, 146],
  35: [6, 30, 54, 78, 102, 126, 150],
  36: [6, 24, 50, 76, 102, 128, 154],
  37: [6, 28, 54, 80, 106, 132, 158],
  38: [6, 32, 58, 84, 110, 136, 162],
  39: [6, 26, 54, 82, 110, 138, 166],
  40: [6, 30, 58, 86, 114, 142, 170],
};

class QrPoint {
  final int x;
  final int y;
  const QrPoint(this.x, this.y);
}

class QrDrawingHelper {
  QrDrawingHelper._();

  static bool isFinderPattern(int x, int y, int moduleCount) {
    if (x < 7 && y < 7) return true;
    if (x >= moduleCount - 7 && y < 7) return true;
    if (x < 7 && y >= moduleCount - 7) return true;
    return false;
  }

  static List<QrPoint> getAlignmentCenters(int moduleCount) {
    final version = (moduleCount - 17) ~/ 4;
    if (version < 2) return const [];
    final coords = qrAlignmentLocations[version];
    if (coords == null) return const [];

    final result = <QrPoint>[];
    for (final row in coords) {
      for (final col in coords) {
        if (row <= 8 && col <= 8) continue;
        if (row <= 8 && col >= moduleCount - 9) continue;
        if (row >= moduleCount - 9 && col <= 8) continue;
        result.add(QrPoint(col, row));
      }
    }
    return result;
  }

  static bool isInsideAlignmentPattern(int x, int y, List<QrPoint> centers) {
    for (final c in centers) {
      if (x >= c.x - 2 && x <= c.x + 2 && y >= c.y - 2 && y <= c.y + 2) {
        return true;
      }
    }
    return false;
  }

  /// Draws position detection eyes on Canvas
  static void drawFinderEyes(Canvas canvas, int moduleCount, double scale, QrStyle style, Paint fgPaint) {
    final positions = [
      const Offset(0, 0),
      Offset((moduleCount - 7).toDouble(), 0),
      Offset(0, (moduleCount - 7).toDouble()),
    ];

    for (final pos in positions) {
      final ox = pos.dx * scale;
      final oy = pos.dy * scale;

      switch (style) {
        case QrStyle.square:
          final outerPath = Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(Rect.fromLTWH(ox, oy, 7 * scale, 7 * scale))
            ..addRect(Rect.fromLTWH(ox + scale, oy + scale, 5 * scale, 5 * scale));
          canvas.drawPath(outerPath, fgPaint);
          canvas.drawRect(Rect.fromLTWH(ox + 2 * scale, oy + 2 * scale, 3 * scale, 3 * scale), fgPaint);
          break;

        case QrStyle.rounded:
          final outerRRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(ox, oy, 7 * scale, 7 * scale),
            Radius.circular(2.1 * scale),
          );
          final innerRRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(ox + scale, oy + scale, 5 * scale, 5 * scale),
            Radius.circular(1.1 * scale),
          );
          final path = Path()
            ..fillType = PathFillType.evenOdd
            ..addRRect(outerRRect)
            ..addRRect(innerRRect);
          canvas.drawPath(path, fgPaint);

          final pupilRRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(ox + 2 * scale, oy + 2 * scale, 3 * scale, 3 * scale),
            Radius.circular(1.5 * scale),
          );
          canvas.drawRRect(pupilRRect, fgPaint);
          break;

        case QrStyle.dots:
          final center = Offset(ox + 3.5 * scale, oy + 3.5 * scale);
          final path = Path()
            ..fillType = PathFillType.evenOdd
            ..addOval(Rect.fromCircle(center: center, radius: 3.5 * scale))
            ..addOval(Rect.fromCircle(center: center, radius: 2.5 * scale));
          canvas.drawPath(path, fgPaint);
          canvas.drawCircle(center, 1.5 * scale, fgPaint);
          break;
      }
    }
  }

  /// Draws alignment patterns on Canvas (used for Dots style)
  static void drawAlignmentPatterns(
    Canvas canvas,
    List<QrPoint> centers,
    double scale,
    QrStyle style,
    Paint fgPaint,
    bool Function(int x, int y) isLogoArea,
  ) {
    if (style != QrStyle.dots) return;

    for (final c in centers) {
      if (isLogoArea(c.x, c.y)) continue;
      final center = Offset((c.x + 0.5) * scale, (c.y + 0.5) * scale);
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: center, radius: 2.5 * scale))
        ..addOval(Rect.fromCircle(center: center, radius: 1.5 * scale));
      canvas.drawPath(path, fgPaint);
      canvas.drawCircle(center, 0.44 * scale, fgPaint);
    }
  }

  /// Draws single data module with appropriate style
  static void drawDataModule(
    Canvas canvas,
    int x,
    int y,
    double scale,
    QrStyle style,
    QrImage qrImage,
    int moduleCount,
    Paint fgPaint,
    bool Function(int x, int y) isLogoArea,
  ) {
    switch (style) {
      case QrStyle.square:
        final hasBottom = y < moduleCount - 1 && qrImage.isDark(y + 1, x) && !isFinderPattern(x, y + 1, moduleCount) && !isLogoArea(x, y + 1);
        final hasRight = x < moduleCount - 1 && qrImage.isDark(y, x + 1) && !isFinderPattern(x + 1, y, moduleCount) && !isLogoArea(x + 1, y);

        // Subpixel overlap when touching a dark neighbor to eliminate rasterizer seams
        final overlap = (scale * 0.04).clamp(0.5, 2.0);
        final right = (x + 1) * scale + (hasRight ? overlap : 0.0);
        final bottom = (y + 1) * scale + (hasBottom ? overlap : 0.0);
        canvas.drawRect(Rect.fromLTRB(x * scale, y * scale, right, bottom), fgPaint);
        break;

      case QrStyle.rounded:
        final hasTop = y > 0 && qrImage.isDark(y - 1, x) && !isFinderPattern(x, y - 1, moduleCount) && !isLogoArea(x, y - 1);
        final hasBottom = y < moduleCount - 1 && qrImage.isDark(y + 1, x) && !isFinderPattern(x, y + 1, moduleCount) && !isLogoArea(x, y + 1);
        final hasLeft = x > 0 && qrImage.isDark(y, x - 1) && !isFinderPattern(x - 1, y, moduleCount) && !isLogoArea(x - 1, y);
        final hasRight = x < moduleCount - 1 && qrImage.isDark(y, x + 1) && !isFinderPattern(x + 1, y, moduleCount) && !isLogoArea(x + 1, y);

        final rTL = (!hasTop && !hasLeft) ? scale * 0.5 : 0.0;
        final rTR = (!hasTop && !hasRight) ? scale * 0.5 : 0.0;
        final rBL = (!hasBottom && !hasLeft) ? scale * 0.5 : 0.0;
        final rBR = (!hasBottom && !hasRight) ? scale * 0.5 : 0.0;

        // Subpixel overlap on interior straight edges where connected to neighbors
        final overlap = (scale * 0.04).clamp(0.5, 2.0);
        final right = (x + 1) * scale + (hasRight ? overlap : 0.0);
        final bottom = (y + 1) * scale + (hasBottom ? overlap : 0.0);

        final rrect = RRect.fromRectAndCorners(
          Rect.fromLTRB(x * scale, y * scale, right, bottom),
          topLeft: Radius.circular(rTL),
          topRight: Radius.circular(rTR),
          bottomLeft: Radius.circular(rBL),
          bottomRight: Radius.circular(rBR),
        );
        canvas.drawRRect(rrect, fgPaint);
        break;

      case QrStyle.dots:
        canvas.drawCircle(Offset((x + 0.5) * scale, (y + 0.5) * scale), scale * 0.44, fgPaint);
        break;
    }
  }

  /// Builds SVG representation for eyes, alignment, and data modules
  static void buildSvgContent({
    required StringBuffer buffer,
    required QrImage qrImage,
    required int moduleCount,
    required QrStyle style,
    required String fgColorHex,
    required bool Function(int x, int y) isLogoArea,
    required List<QrPoint> alignmentCenters,
  }) {
    // 1. Draw Finder Eyes
    final positions = [
      const QrPoint(0, 0),
      QrPoint(moduleCount - 7, 0),
      QrPoint(0, moduleCount - 7),
    ];

    for (final pos in positions) {
      final ox = pos.x;
      final oy = pos.y;

      switch (style) {
        case QrStyle.square:
          buffer.writeln('  <path fill-rule="evenodd" d="M $ox $oy h 7 v 7 h -7 z M ${ox + 1} ${oy + 1} v 5 h 5 v -5 z" fill="$fgColorHex"/>');
          buffer.writeln('  <rect x="${ox + 2}" y="${oy + 2}" width="3" height="3" fill="$fgColorHex"/>');
          break;

        case QrStyle.rounded:
          final outerPath = 'M ${ox + 2.1},$oy h 2.8 a 2.1,2.1 0 0 1 2.1,2.1 v 2.8 a 2.1,2.1 0 0 1 -2.1,2.1 h -2.8 a 2.1,2.1 0 0 1 -2.1,-2.1 v -2.8 a 2.1,2.1 0 0 1 2.1,-2.1 z';
          final innerPath = 'M ${ox + 2.1},${oy + 1} h 2.8 a 1.1,1.1 0 0 1 1.1,1.1 v 2.8 a 1.1,1.1 0 0 1 -1.1,1.1 h -2.8 a 1.1,1.1 0 0 1 -1.1,-1.1 v -2.8 a 1.1,1.1 0 0 1 1.1,-1.1 z';
          buffer.writeln('  <path fill-rule="evenodd" d="$outerPath $innerPath" fill="$fgColorHex"/>');
          buffer.writeln('  <rect x="${ox + 2}" y="${oy + 2}" width="3" height="3" rx="1.5" ry="1.5" fill="$fgColorHex"/>');
          break;

        case QrStyle.dots:
          buffer.writeln('  <circle cx="${ox + 3.5}" cy="${oy + 3.5}" r="3" fill="none" stroke="$fgColorHex" stroke-width="1"/>');
          buffer.writeln('  <circle cx="${ox + 3.5}" cy="${oy + 3.5}" r="1.5" fill="$fgColorHex"/>');
          break;
      }
    }

    // 2. Draw Alignment Patterns for Dots style
    if (style == QrStyle.dots) {
      for (final c in alignmentCenters) {
        if (isLogoArea(c.x, c.y)) continue;
        buffer.writeln('  <circle cx="${c.x + 0.5}" cy="${c.y + 0.5}" r="2" fill="none" stroke="$fgColorHex" stroke-width="1"/>');
        buffer.writeln('  <circle cx="${c.x + 0.5}" cy="${c.y + 0.5}" r="0.44" fill="$fgColorHex"/>');
      }
    }

    // 3. Draw Data Modules
    for (int y = 0; y < moduleCount; y++) {
      for (int x = 0; x < moduleCount; x++) {
        if (isFinderPattern(x, y, moduleCount) || isLogoArea(x, y)) {
          continue;
        }
        if (style == QrStyle.dots && isInsideAlignmentPattern(x, y, alignmentCenters)) {
          continue;
        }

        if (qrImage.isDark(y, x)) {
          switch (style) {
            case QrStyle.square:
              final hasBottom = y < moduleCount - 1 && qrImage.isDark(y + 1, x) && !isFinderPattern(x, y + 1, moduleCount) && !isLogoArea(x, y + 1);
              final hasRight = x < moduleCount - 1 && qrImage.isDark(y, x + 1) && !isFinderPattern(x + 1, y, moduleCount) && !isLogoArea(x + 1, y);
              final w = hasRight ? "1.05" : "1";
              final h = hasBottom ? "1.05" : "1";
              buffer.writeln('  <rect x="$x" y="$y" width="$w" height="$h" fill="$fgColorHex"/>');
              break;

            case QrStyle.rounded:
              final hasTop = y > 0 && qrImage.isDark(y - 1, x) && !isFinderPattern(x, y - 1, moduleCount) && !isLogoArea(x, y - 1);
              final hasBottom = y < moduleCount - 1 && qrImage.isDark(y + 1, x) && !isFinderPattern(x, y + 1, moduleCount) && !isLogoArea(x, y + 1);
              final hasLeft = x > 0 && qrImage.isDark(y, x - 1) && !isFinderPattern(x - 1, y, moduleCount) && !isLogoArea(x - 1, y);
              final hasRight = x < moduleCount - 1 && qrImage.isDark(y, x + 1) && !isFinderPattern(x + 1, y, moduleCount) && !isLogoArea(x + 1, y);

              final rTL = (!hasTop && !hasLeft) ? 0.5 : 0.0;
              final rTR = (!hasTop && !hasRight) ? 0.5 : 0.0;
              final rBL = (!hasBottom && !hasLeft) ? 0.5 : 0.0;
              final rBR = (!hasBottom && !hasRight) ? 0.5 : 0.0;

              final right = (x + 1.0) + (hasRight ? 0.05 : 0.0);
              final bottom = (y + 1.0) + (hasBottom ? 0.05 : 0.0);

              if (rTL == 0 && rTR == 0 && rBL == 0 && rBR == 0) {
                final w = hasRight ? "1.05" : "1";
                final h = hasBottom ? "1.05" : "1";
                buffer.writeln('  <rect x="$x" y="$y" width="$w" height="$h" fill="$fgColorHex"/>');
              } else if (rTL == 0.5 && rTR == 0.5 && rBL == 0.5 && rBR == 0.5) {
                buffer.writeln('  <circle cx="${x + 0.5}" cy="${y + 0.5}" r="0.5" fill="$fgColorHex"/>');
              } else {
                final d = StringBuffer()
                  ..write('M ${x + rTL},$y ')
                  ..write('H ${right - rTR} ')
                  ..write(rTR > 0 ? 'a 0.5,0.5 0 0 1 0.5,0.5 ' : '')
                  ..write('V ${bottom - rBR} ')
                  ..write(rBR > 0 ? 'a 0.5,0.5 0 0 1 -0.5,0.5 ' : '')
                  ..write('H ${x + rBL} ')
                  ..write(rBL > 0 ? 'a 0.5,0.5 0 0 1 -0.5,-0.5 ' : '')
                  ..write('V ${y + rTL} ')
                  ..write(rTL > 0 ? 'a 0.5,0.5 0 0 1 0.5,-0.5 ' : '')
                  ..write('z');
                buffer.writeln('  <path d="${d.toString().trim()}" fill="$fgColorHex"/>');
              }
              break;

            case QrStyle.dots:
              buffer.writeln('  <circle cx="${x + 0.5}" cy="${y + 0.5}" r="0.44" fill="$fgColorHex"/>');
              break;
          }
        }
      }
    }
  }
}
