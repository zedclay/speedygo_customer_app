import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SplashMetrics {
  const SplashMetrics._();

  static const designWidth = 390.0;
  static const logoBox = 146.0;
  static const assetVisibleFraction = 394 / 500;
  static const loaderSize = 28.0;
  static const loaderBottom = 98.0;
  static const logoVerticalFactor = 0.45;
  static const assetPath = 'assets/branding/speedygo_logo.png';

  static const gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF135BC9),
      Color(0xFF0C43A4),
      Color(0xFF08307D),
      Color(0xFF06225B),
      Color(0xFF051944),
    ],
    stops: [0.0, 0.32, 0.64, 0.85, 1.0],
  );

  static double scale(Size size) => size.width / designWidth;

  static double logoAssetSize(Size size) {
    return logoBox / assetVisibleFraction * scale(size);
  }
}

class SplashBackdropPainter extends CustomPainter {
  const SplashBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = SplashMetrics.scale(size);

    final topSweep = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.08, size.height * 0.02),
        size.width * 0.85,
        const [
          Color.fromRGBO(96, 165, 250, 0.28),
          Color.fromRGBO(37, 99, 235, 0.08),
          Color(0x00000000),
        ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawCircle(
      Offset(size.width * 0.05, -size.height * 0.02),
      size.width * 0.7,
      topSweep,
    );

    canvas.save();
    canvas.translate(-16 * s, -48 * s);
    canvas.scale(s, s);
    final upperGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..shader = ui.Gradient.linear(
        const Offset(-40, 0),
        const Offset(360, 240),
        const [
          Color.fromRGBO(147, 197, 253, 0.9),
          Color.fromRGBO(59, 130, 246, 0.4),
          Color.fromRGBO(29, 78, 216, 0.0),
        ],
        const [0.0, 0.5, 1.0],
      );
    final upperHair = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color.fromRGBO(96, 165, 250, 0.6);
    final upper = Path()
      ..moveTo(-40, 0)
      ..cubicTo(40, 160, 160, 210, 320, 180)
      ..cubicTo(390, 168, 430, 130, 460, 90);
    canvas.drawPath(upper, upperGlow);
    final upperInner = Path()
      ..moveTo(-60, 20)
      ..cubicTo(50, 180, 170, 230, 330, 200)
      ..cubicTo(400, 188, 450, 150, 480, 110);
    canvas.drawPath(upperInner, upperHair);
    canvas.restore();

    canvas.save();
    canvas.translate(-10 * s, size.height - 520 * s);
    canvas.scale(s, s);
    final ribbonGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
      ..shader = ui.Gradient.linear(
        const Offset(-60, 480),
        const Offset(480, 180),
        const [
          Color.fromRGBO(34, 211, 238, 0.6),
          Color.fromRGBO(56, 189, 248, 0.5),
          Color.fromRGBO(37, 99, 235, 0.2),
          Color.fromRGBO(30, 58, 138, 0.0),
        ],
        const [0.0, 0.4, 0.8, 1.0],
      );
    final ribbonHair = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color.fromRGBO(125, 211, 252, 0.6);
    final ribbon = Path()
      ..moveTo(-60, 480)
      ..cubicTo(80, 390, 200, 300, 480, 180);
    canvas.drawPath(ribbon, ribbonGlow);
    canvas.drawPath(ribbon, ribbonHair);
    canvas.restore();

    final depth = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 1.05, size.height * 1.05),
        size.width * 0.85,
        const [Color.fromRGBO(14, 52, 133, 0.55), Color(0x00000000)],
        const [0.0, 1.0],
      );
    canvas.drawCircle(
      Offset(size.width * 1.02, size.height * 1.04),
      size.width * 0.7,
      depth,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SplashLoaderPainter extends CustomPainter {
  const SplashLoaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 1.4;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.75
      ..color = const Color.fromRGBO(96, 165, 250, 0.4);
    canvas.drawCircle(center, radius, track);

    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.75
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFA3E635);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5707963267948966,
      1.5707963267948966,
      false,
      accent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
