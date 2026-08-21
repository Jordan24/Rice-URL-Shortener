import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate official Rice PNG logos', () async {
    final dir = Directory('assets/logos');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    await generateShieldPng('assets/logos/rice_shield.png');
    await generateOwlPng('assets/logos/rice_owl.png');
    await generateRPng('assets/logos/rice_r.png');

    expect(File('assets/logos/rice_shield.png').existsSync(), isTrue);
    expect(File('assets/logos/rice_owl.png').existsSync(), isTrue);
    expect(File('assets/logos/rice_r.png').existsSync(), isTrue);
  });
}

const riceBlue = Color(0xFF00205B);
const laurelGold = Color(0xFFC19B4C);
const white = Color(0xFFFFFFFF);

Future<void> generateShieldPng(String path) async {
  const size = 512.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

  final shieldPaint = Paint()
    ..color = riceBlue
    ..isAntiAlias = true
    ..style = PaintingStyle.fill;

  final goldBorder = Paint()
    ..color = laurelGold
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = 14;

  final whiteChevronPaint = Paint()
    ..color = white
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.square
    ..strokeJoin = StrokeJoin.miter
    ..strokeWidth = 22;

  final goldChevronPaint = Paint()
    ..color = laurelGold
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.square
    ..strokeJoin = StrokeJoin.miter
    ..strokeWidth = 22;

  final shieldPath = Path()
    ..moveTo(64, 48)
    ..lineTo(448, 48)
    ..lineTo(448, 250)
    ..cubicTo(448, 380, 256, 464, 256, 464)
    ..cubicTo(256, 464, 64, 380, 64, 250)
    ..close();

  canvas.drawPath(shieldPath, shieldPaint);
  canvas.drawPath(shieldPath, goldBorder);

  canvas.save();
  canvas.clipPath(shieldPath);

  final chevron1 = Path()
    ..moveTo(50, 260)
    ..lineTo(256, 150)
    ..lineTo(462, 260);
  canvas.drawPath(chevron1, whiteChevronPaint);

  final chevron2 = Path()
    ..moveTo(50, 310)
    ..lineTo(256, 200)
    ..lineTo(462, 310);
  canvas.drawPath(chevron2, goldChevronPaint);

  canvas.restore();

  _drawAthenianOwl(canvas, const Offset(165, 110), 0.38, owlColor: white, accentColor: laurelGold);
  _drawAthenianOwl(canvas, const Offset(347, 110), 0.38, owlColor: white, accentColor: laurelGold);
  _drawAthenianOwl(canvas, const Offset(256, 360), 0.44, owlColor: laurelGold, accentColor: white);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(byteData!.buffer.asUint8List());
}

Future<void> generateOwlPng(String path) async {
  const size = 512.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

  final bgPaint = Paint()
    ..color = riceBlue
    ..isAntiAlias = true;
  final borderPaint = Paint()
    ..color = laurelGold
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12;

  canvas.drawCircle(const Offset(256, 256), 236, bgPaint);
  canvas.drawCircle(const Offset(256, 256), 236, borderPaint);

  final innerRing = Paint()
    ..color = white.withValues(alpha: 0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  canvas.drawCircle(const Offset(256, 256), 222, innerRing);

  _drawAthenianOwl(canvas, const Offset(256, 256), 1.4, owlColor: white, accentColor: laurelGold);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(byteData!.buffer.asUint8List());
}

Future<void> generateRPng(String path) async {
  const size = 512.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

  final bgPaint = Paint()
    ..color = riceBlue
    ..isAntiAlias = true;
  final borderPaint = Paint()
    ..color = laurelGold
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12;

  canvas.drawCircle(const Offset(256, 256), 236, bgPaint);
  canvas.drawCircle(const Offset(256, 256), 236, borderPaint);

  _drawGothicR(canvas, const Offset(256, 256), 330, color: white, accentColor: laurelGold);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(byteData!.buffer.asUint8List());
}

void _drawAthenianOwl(
  Canvas canvas,
  Offset center,
  double scale, {
  required Color owlColor,
  required Color accentColor,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(scale, scale);

  final mainPaint = Paint()
    ..color = owlColor
    ..isAntiAlias = true
    ..style = PaintingStyle.fill;
  final accentPaint = Paint()
    ..color = accentColor
    ..isAntiAlias = true
    ..style = PaintingStyle.fill;
  final whitePaint = Paint()
    ..color = white
    ..isAntiAlias = true
    ..style = PaintingStyle.fill;
  final strokeAccent = Paint()
    ..color = accentColor
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;

  final perchRect = RRect.fromRectAndRadius(const Rect.fromLTWH(-48, 54, 96, 12), const Radius.circular(6));
  canvas.drawRRect(perchRect, accentPaint);

  final bodyPath = Path()
    ..moveTo(-36, -20)
    ..cubicTo(-46, 10, -42, 45, -30, 56)
    ..lineTo(30, 56)
    ..cubicTo(42, 45, 46, 10, 36, -20)
    ..cubicTo(40, -45, 20, -60, 0, -60)
    ..cubicTo(-20, -60, -40, -45, -36, -20)
    ..close();
  canvas.drawPath(bodyPath, mainPaint);

  final browPath = Path()
    ..moveTo(-34, -40)
    ..quadraticBezierTo(-18, -50, 0, -36)
    ..quadraticBezierTo(18, -50, 34, -40);
  canvas.drawPath(browPath, strokeAccent);

  const eyeRadius = 18.0;
  const eyeOffsetX = 16.0;
  const eyeOffsetY = -22.0;

  canvas.drawCircle(const Offset(-eyeOffsetX, eyeOffsetY), eyeRadius, accentPaint);
  canvas.drawCircle(const Offset(eyeOffsetX, eyeOffsetY), eyeRadius, accentPaint);

  canvas.drawCircle(const Offset(-eyeOffsetX, eyeOffsetY), eyeRadius * 0.75, whitePaint);
  canvas.drawCircle(const Offset(eyeOffsetX, eyeOffsetY), eyeRadius * 0.75, whitePaint);

  final darkEye = Paint()..color = riceBlue;
  canvas.drawCircle(const Offset(-eyeOffsetX, eyeOffsetY), eyeRadius * 0.45, darkEye);
  canvas.drawCircle(const Offset(eyeOffsetX, eyeOffsetY), eyeRadius * 0.45, darkEye);

  canvas.drawCircle(const Offset(-eyeOffsetX + 2, eyeOffsetY - 2), 2.5, whitePaint);
  canvas.drawCircle(const Offset(eyeOffsetX + 2, eyeOffsetY - 2), 2.5, whitePaint);

  final beakPath = Path()
    ..moveTo(-6, -10)
    ..lineTo(6, -10)
    ..lineTo(0, 8)
    ..close();
  canvas.drawPath(beakPath, accentPaint);

  for (int row = 0; row < 3; row++) {
    final y = 14.0 + row * 12.0;
    final w = 24.0 - row * 5.0;
    final arc = Path()
      ..moveTo(-w, y)
      ..quadraticBezierTo(0, y + 8, w, y);
    canvas.drawPath(arc, strokeAccent);
  }

  canvas.drawCircle(const Offset(-14, 52), 4, accentPaint);
  canvas.drawCircle(const Offset(-6, 52), 4, accentPaint);
  canvas.drawCircle(const Offset(6, 52), 4, accentPaint);
  canvas.drawCircle(const Offset(14, 52), 4, accentPaint);

  canvas.restore();
}

void _drawGothicR(
  Canvas canvas,
  Offset center,
  double size, {
  required Color color,
  required Color accentColor,
}) {
  canvas.save();
  canvas.translate(center.dx - size / 2, center.dy - size / 2);
  final s = size / 300.0;
  canvas.scale(s, s);

  final rPaint = Paint()
    ..color = color
    ..isAntiAlias = true
    ..style = PaintingStyle.fill;
  final accentPaint = Paint()
    ..color = accentColor
    ..isAntiAlias = true
    ..style = PaintingStyle.fill;

  final stemPath = Path()
    ..moveTo(55, 65)
    ..lineTo(85, 45)
    ..lineTo(125, 45)
    ..lineTo(125, 135)
    ..lineTo(90, 135)
    ..lineTo(65, 160)
    ..lineTo(90, 185)
    ..lineTo(125, 185)
    ..lineTo(125, 230)
    ..lineTo(60, 255)
    ..lineTo(150, 255)
    ..lineTo(145, 230)
    ..lineTo(145, 45)
    ..close();
  canvas.drawPath(stemPath, rPaint);

  final lobePath = Path()
    ..moveTo(125, 45)
    ..cubicTo(195, 30, 235, 75, 235, 115)
    ..cubicTo(235, 155, 195, 175, 130, 175)
    ..lineTo(130, 145)
    ..cubicTo(175, 145, 195, 135, 195, 115)
    ..cubicTo(195, 85, 170, 75, 125, 75)
    ..close();
  canvas.drawPath(lobePath, rPaint);

  final midBar = Path()
    ..moveTo(120, 145)
    ..lineTo(170, 145)
    ..lineTo(185, 175)
    ..lineTo(120, 175)
    ..close();
  canvas.drawPath(midBar, rPaint);

  final legPath = Path()
    ..moveTo(150, 160)
    ..cubicTo(185, 175, 195, 205, 215, 235)
    ..cubicTo(230, 255, 250, 260, 265, 245)
    ..cubicTo(260, 240, 255, 230, 250, 215)
    ..cubicTo(240, 190, 215, 170, 175, 155)
    ..close();
  canvas.drawPath(legPath, rPaint);

  final diamondPath = Path()
    ..moveTo(160, 100)
    ..lineTo(175, 115)
    ..lineTo(160, 130)
    ..lineTo(145, 115)
    ..close();
  canvas.drawPath(diamondPath, accentPaint);

  canvas.restore();
}
