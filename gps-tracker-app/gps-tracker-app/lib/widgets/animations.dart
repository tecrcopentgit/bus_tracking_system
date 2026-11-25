import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../theme/app_theme.dart';

/// Fades + slides its child up when first shown. Use increasing [delay]s on
/// siblings for a staggered entrance.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.dy = 0.14,
    this.duration = const Duration(milliseconds: 560),
  });

  final Widget child;
  final Duration delay;
  final double dy;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _t = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, widget.dy), end: Offset.zero).animate(_a),
        child: widget.child,
      ),
    );
  }
}

/// Expanding, fading ring (live "radar" effect).
class PulseRing extends StatefulWidget {
  const PulseRing({super.key, required this.color, this.size = 64, this.maxScale = 1.7});
  final Color color;
  final double size;
  final double maxScale;

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.scale(
        scale: 1 + (widget.maxScale - 1) * _c.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withAlpha(((1 - _c.value) * 90).round()),
          ),
        ),
      ),
    );
  }
}

/// Small status dot that pulses while [animate] is true.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color, this.size = 10, this.animate = true});
  final Color color;
  final double size;
  final bool animate;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.size * 2.2;
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.animate)
            AnimatedBuilder(
              animation: _c,
              builder: (_, __) => Transform.scale(
                scale: 1 + _c.value * 1.1,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withAlpha(((1 - _c.value) * 120).round()),
                  ),
                ),
              ),
            ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

/// Gentle floating motion.
class Bobbing extends StatefulWidget {
  const Bobbing({
    super.key,
    required this.child,
    this.amplitude = 6,
    this.duration = const Duration(milliseconds: 1800),
  });
  final Widget child;
  final double amplitude;
  final Duration duration;

  @override
  State<Bobbing> createState() => _BobbingState();
}

class _BobbingState extends State<Bobbing> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, (Curves.easeInOut.transform(_c.value) - 0.5) * 2 * widget.amplitude),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Slowly rotating sun-like rays (used behind the bus icon on the live card).
class Rays extends StatefulWidget {
  const Rays({super.key, this.size = 110, this.color = AppColors.terracottaLight});
  final double size;
  final Color color;

  @override
  State<Rays> createState() => _RaysState();
}

class _RaysState extends State<Rays> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _RaysPainter(widget.color),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final outer = size.width / 2;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final inner = outer - (i.isEven ? 14 : 9);
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * inner,
        c + Offset(math.cos(a), math.sin(a)) * outer,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}

/// Number that counts smoothly to its new value.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.style});
  final double value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(v.round().toString(), style: style),
    );
  }
}

/// "5s ago" that keeps ticking every second.
class LiveAgo extends StatefulWidget {
  const LiveAgo({super.key, required this.time, this.style});
  final DateTime? time;
  final TextStyle? style;

  @override
  State<LiveAgo> createState() => _LiveAgoState();
}

class _LiveAgoState extends State<LiveAgo> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.time;
    return Text(t == null ? '—' : formatAgo(t), style: widget.style);
  }
}
