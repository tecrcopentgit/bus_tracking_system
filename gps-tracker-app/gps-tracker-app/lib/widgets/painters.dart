import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Looping desert-road scene (sun, parallax hills, moving road dashes).
/// [t] runs 0..1 and every layer loops seamlessly.
class RoadScenePainter extends CustomPainter {
  RoadScenePainter(this.t);
  final double t;

  void _hill(Canvas canvas, Size size, Color color, double amp, double period,
      double yBase, double phase) {
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width + 3; x += 3) {
      final y = yBase + math.sin((x / period + phase) * 2 * math.pi) * amp;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final sun = Offset(w * 0.74, h * 0.34);
    canvas.drawCircle(
      sun,
      60,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );
    canvas.drawCircle(sun, 34, Paint()..color = const Color(0xFFFFE6C7));

    _hill(canvas, size, const Color(0xFFE9976B), 14, w * 0.9, h * 0.58, t);
    _hill(canvas, size, const Color(0xFFD97746), 18, w * 0.62, h * 0.67, t * 2);
    _hill(canvas, size, const Color(0xFFA9441D), 12, w * 0.46, h * 0.75, t * 3);

    // road
    final roadTop = h * 0.82;
    canvas.drawRect(Rect.fromLTWH(0, roadTop, w, h - roadTop), Paint()..color = AppColors.charcoal);
    const dash = 28.0, gap = 22.0, period = dash + gap;
    final offset = (t * 4 * period) % period;
    final dashPaint = Paint()..color = const Color(0xFFF2D8B8);
    final y = roadTop + (h - roadTop) * 0.5;
    for (double x = -period + (period - offset); x < w + period; x += period) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y - 2, dash, 4), const Radius.circular(2)),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(RoadScenePainter old) => old.t != t;
}

/// Vertical stack of random-looking bars, seeded so it is stable per ticket.
class BarcodePainter extends CustomPainter {
  BarcodePainter({required this.seed, required this.color});
  final String seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed.hashCode);
    final paint = Paint()..color = color;
    double y = 0;
    while (y < size.height) {
      final th = 1.5 + rnd.nextInt(4) * 1.2;
      if (y + th > size.height) break;
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, th), paint);
      y += th + 1.6 + rnd.nextInt(3);
    }
  }

  @override
  bool shouldRepaint(BarcodePainter old) => old.seed != seed || old.color != color;
}

class DashedLinePainter extends CustomPainter {
  DashedLinePainter({this.color = AppColors.line});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(math.min(x + 8, size.width), size.height / 2), paint);
      x += 15;
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter old) => old.color != color;
}

/// 240° speedometer arc. [progress] is 0..1.
class SpeedGaugePainter extends CustomPainter {
  SpeedGaugePainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 16;
    final rect = Rect.fromCircle(center: center, radius: r);
    const start = 150 * math.pi / 180;
    const sweep = 240 * math.pi / 180;

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..color = AppColors.line,
    );

    // ticks
    final tick = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.muted.withAlpha(120);
    for (var i = 0; i <= 24; i++) {
      final a = start + sweep * i / 24;
      final long = i % 6 == 0;
      final r1 = r - 22, r2 = r - (long ? 36 : 30);
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * r1,
        center + Offset(math.cos(a), math.sin(a)) * r2,
        tick,
      );
    }

    final p = math.max(0.0, math.min(1.0, progress));
    if (p > 0.001) {
      canvas.drawArc(
        rect,
        start,
        sweep * p,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(
            colors: [AppColors.terracottaLight, AppColors.terracottaDeep],
          ).createShader(rect),
      );
      final a = start + sweep * p;
      final knob = center + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(knob, 11, Paint()..color = Colors.white);
      canvas.drawCircle(knob, 6, Paint()..color = AppColors.terracotta);
    }
  }

  @override
  bool shouldRepaint(SpeedGaugePainter old) => old.progress != progress;
}
