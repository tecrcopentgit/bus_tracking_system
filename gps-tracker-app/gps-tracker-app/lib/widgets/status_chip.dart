import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'animations.dart';

class StatusStyle {
  const StatusStyle(this.label, this.color);
  final String label;
  final Color color;
}

StatusStyle statusStyle(String status) {
  switch (status) {
    case 'moving':
      return const StatusStyle('Moving', AppColors.green);
    case 'idle':
      return const StatusStyle('Idle', AppColors.amber);
    case 'offline':
      return const StatusStyle('Offline', AppColors.pink);
    default:
      return const StatusStyle('Waiting for signal', AppColors.muted);
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.dark = false});
  final String status;
  final bool dark; // for use on dark surfaces

  @override
  Widget build(BuildContext context) {
    final s = statusStyle(status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(6, 3, 12, 3),
      decoration: BoxDecoration(
        color: s.color.withAlpha(dark ? 55 : 36),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseDot(color: s.color, size: 8, animate: status == 'moving'),
          const SizedBox(width: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              s.label,
              key: ValueKey(s.label),
              style: TextStyle(
                color: dark ? Colors.white : s.color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
