import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pressable.dart';

/// Terracotta pill button with press animation and a busy spinner.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return Pressable(
      onTap: enabled ? onPressed : null,
      scale: 0.96,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onPressed == null && !busy ? 0.55 : 1,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: AppGradients.terracotta,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.terracottaDeep.withAlpha(95),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: busy
                ? const SizedBox(
                    key: ValueKey('busy'),
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Round soft button. Set [active] to highlight it (e.g. "following").
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.size = 48,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Pressable(
      onTap: onTap,
      scale: 0.88,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.terracotta : AppColors.cream,
          boxShadow: neuShadow,
        ),
        child: Icon(icon, size: size * 0.46, color: active ? Colors.white : AppColors.ink),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Refresh icon that spins one full turn each time it is tapped.
class SpinRefreshButton extends StatefulWidget {
  const SpinRefreshButton({super.key, required this.onTap});
  final VoidCallback? onTap;

  @override
  State<SpinRefreshButton> createState() => _SpinRefreshButtonState();
}

class _SpinRefreshButtonState extends State<SpinRefreshButton> {
  double _turns = 0;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: widget.onTap == null
          ? null
          : () {
              setState(() => _turns += 1);
              widget.onTap!();
            },
      scale: 0.88,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.cream,
          boxShadow: neuShadow,
        ),
        child: AnimatedRotation(
          turns: _turns,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          child: const Icon(Icons.refresh_rounded, size: 24, color: AppColors.terracotta),
        ),
      ),
    );
  }
}
