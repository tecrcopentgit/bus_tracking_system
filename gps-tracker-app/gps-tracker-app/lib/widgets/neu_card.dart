import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pressable.dart';

/// Soft cream card with the warm neumorphic shadow. Pass [onTap] to make it
/// tappable (it then squishes on press).
class NeuCard extends StatelessWidget {
  const NeuCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 26,
    this.onTap,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.97,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: gradient == null ? AppColors.cream : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withAlpha(150)),
          boxShadow: neuShadow,
        ),
        child: child,
      ),
    );
  }
}
