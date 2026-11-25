import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'animations.dart';
import 'pressable.dart';

/// Floating pill navigation with a raised, pulsing "Live map" button in the middle.
class BusBottomNav extends StatelessWidget {
  const BusBottomNav({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  Widget _item(int i, IconData icon, IconData activeIcon, String label) {
    final sel = index == i;
    return Expanded(
      child: Pressable(
        onTap: () => onChanged(i),
        scale: 0.88,
        child: SizedBox(
          height: 74,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: sel ? 1.18 : 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Icon(
                  sel ? activeIcon : icon,
                  size: 25,
                  color: sel ? AppColors.terracotta : AppColors.muted,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                  color: sel ? AppColors.terracotta : AppColors.muted,
                ),
                child: Text(label),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                margin: const EdgeInsets.only(top: 3),
                width: sel ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fabSelected = index == 2;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: SizedBox(
          height: 74,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 74,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(38),
                  border: Border.all(color: Colors.white.withAlpha(160)),
                  boxShadow: neuShadow,
                ),
                child: Row(
                  children: [
                    _item(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                    _item(1, Icons.alt_route_outlined, Icons.alt_route_rounded, 'Route'),
                    const SizedBox(width: 80),
                    _item(3, Icons.directions_bus_outlined, Icons.directions_bus_rounded, 'Vehicle'),
                    _item(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
                  ],
                ),
              ),
              Positioned(
                top: -24,
                child: Pressable(
                  onTap: () => onChanged(2),
                  scale: 0.9,
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const PulseRing(color: AppColors.terracotta, size: 64),
                        AnimatedScale(
                          scale: fabSelected ? 1.1 : 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          child: Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppGradients.terracotta,
                              border: Border.all(color: AppColors.cream, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.terracottaDeep.withAlpha(110),
                                  blurRadius: 18,
                                  offset: const Offset(0, 9),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 30),
                          ),
                        ),
                      ],
                    ),
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
