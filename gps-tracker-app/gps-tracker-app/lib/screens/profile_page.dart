import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../providers/auth_provider.dart';
import '../providers/tracking_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/neu_card.dart';
import '../widgets/pressable.dart';

/// Profile: terracotta header with a pulsing avatar, account details and a
/// confirmed sign-out. Works even when no route/vehicle is assigned yet.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Sign out?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('You will need to sign in again to see your bus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out', style: TextStyle(color: AppColors.pink)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final t = context.watch<TrackingProvider>();
    final top = MediaQuery.of(context).padding.top;
    final name = user?.fullName ?? 'Passenger';
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: [
        FadeSlideIn(
          dy: -0.1,
          child: Container(
            padding: EdgeInsets.fromLTRB(24, top + 24, 24, 34),
            decoration: const BoxDecoration(
              gradient: AppGradients.terracotta,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(46)),
              boxShadow: darkShadow,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const PulseRing(color: Colors.white, size: 96, maxScale: 1.35),
                      Container(
                        width: 96,
                        height: 96,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: darkShadow,
                        ),
                        child: Text(initial,
                            style: const TextStyle(
                                color: AppColors.terracotta, fontSize: 44, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(user?.email ?? '',
                    style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 14)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            children: [
              _Row(0, Icons.alt_route_rounded, 'Assigned route', t.route?.name ?? 'Not assigned yet'),
              _Row(1, Icons.directions_bus_rounded, 'Assigned vehicle',
                  t.vehicle == null ? 'Not assigned yet' : '${t.vehicle!.code} · ${t.vehicle!.plateNumber}'),
              _Row(2, Icons.dns_rounded, 'Server', apiBaseUrl),
              _Row(3, Icons.info_outline_rounded, 'App version', '1.0.0'),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 460),
                child: Pressable(
                  onTap: () => _confirmSignOut(context),
                  scale: 0.96,
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.pink, width: 2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.pink),
                        SizedBox(width: 10),
                        Text('Sign out',
                            style: TextStyle(
                                color: AppColors.pink, fontSize: 16, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.index, this.icon, this.label, this.value);
  final int index;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: Duration(milliseconds: 120 + index * 80),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: NeuCard(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.terracotta.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.terracotta, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
