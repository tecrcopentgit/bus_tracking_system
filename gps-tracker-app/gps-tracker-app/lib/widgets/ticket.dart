import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'painters.dart';
import 'pressable.dart';

/// Rounded rectangle with a half-circle bitten out of the top and bottom edge
/// at [stubWidth] from the right (a tear-off ticket stub).
class TicketClipper extends CustomClipper<Path> {
  TicketClipper({required this.stubWidth, this.radius = 28, this.notch = 12});
  final double stubWidth;
  final double radius;
  final double notch;

  @override
  Path getClip(Size size) {
    final base = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final x = size.width - stubWidth;
    final cut = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(x, size.height), radius: notch));
    return Path.combine(PathOperation.difference, base, cut);
  }

  @override
  bool shouldReclip(TicketClipper old) => old.stubWidth != stubWidth;
}

/// Boarding-pass shape: notches bitten out of the left and right edges at [notchY].
class PassClipper extends CustomClipper<Path> {
  PassClipper({required this.notchY, this.radius = 30, this.notch = 13});
  final double notchY;
  final double radius;
  final double notch;

  @override
  Path getClip(Size size) {
    final base = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final cut = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, notchY), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(size.width, notchY), radius: notch));
    return Path.combine(PathOperation.difference, base, cut);
  }

  @override
  bool shouldReclip(PassClipper old) => old.notchY != notchY;
}

class TicketItem {
  const TicketItem(this.icon, this.label, this.caption);
  final IconData icon;
  final String label;
  final String caption;
}

/// "BUS PASS" ticket for the assigned route.
class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.seed,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final List<TicketItem> items;
  final String seed;
  final VoidCallback? onTap;

  static const double _stub = 96;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.97,
      child: PhysicalShape(
        color: AppColors.cream,
        elevation: 10,
        shadowColor: const Color(0x80765238),
        clipBehavior: Clip.antiAlias,
        clipper: TicketClipper(stubWidth: _stub),
        child: SizedBox(
          height: 158,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BUS PASS',
                        style: TextStyle(
                          color: AppColors.terracotta,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [for (final i in items) _Item(i)],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: _stub,
                child: DecoratedBox(
                  decoration: const BoxDecoration(gradient: AppGradients.terracotta),
                  child: Stack(
                    children: [
                      Positioned(
                        left: -26,
                        top: 24,
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(34),
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 14,
                        bottom: 22,
                        child: Icon(Icons.directions_bus_rounded, color: Colors.white, size: 34),
                      ),
                      Positioned(
                        right: 14,
                        top: 22,
                        bottom: 22,
                        width: 26,
                        child: CustomPaint(
                          painter: BarcodePainter(seed: seed, color: const Color(0xCC2B1409)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.item);
  final TicketItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 4, color: AppColors.terracotta),
        const SizedBox(height: 2),
        Text(item.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        Text(item.caption, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      ],
    );
  }
}
