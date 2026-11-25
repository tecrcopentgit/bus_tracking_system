import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/admin_models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../animations.dart';
import '../buttons.dart';
import '../neu_card.dart';
import '../pressable.dart';
import '../status_chip.dart';

void showMessage(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: error ? AppColors.pink : AppColors.charcoal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
}

/// Runs [action]; shows the server's message on failure. Returns true on success.
Future<bool> runAction(BuildContext context, Future<void> Function() action,
    {String? success}) async {
  try {
    await action();
    if (success != null && context.mounted) showMessage(context, success);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) showMessage(context, e.message, error: true);
    return false;
  }
}

Future<T?> showAdminSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    ),
  );
}

Future<bool> confirm(BuildContext context, String title, String message, String action) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(action, style: const TextStyle(color: AppColors.pink)),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Page title row with refresh + account menu (sign out).
class AdminHeader extends StatelessWidget {
  const AdminHeader({super.key, required this.title, required this.subtitle, this.onRefresh});

  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return FadeSlideIn(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
              ],
            ),
          ),
          if (onRefresh != null) SpinRefreshButton(onTap: onRefresh),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (v) {
              if (v == 'logout') context.read<AuthProvider>().logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(user?.email ?? '', style: const TextStyle(color: AppColors.muted)),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [Icon(Icons.logout_rounded, size: 20), SizedBox(width: 12), Text('Sign out')],
                ),
              ),
            ],
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: AppGradients.terracotta,
                shape: BoxShape.circle,
                boxShadow: neuShadow,
              ),
              child: Text(
                (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'A',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient "add" pill used on list pages.
class AddFab extends StatelessWidget {
  const AddFab({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.92,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppGradients.terracotta,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.terracottaDeep.withAlpha(110),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(14),
      radius: 22,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withAlpha(38), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CountUp(value: value.toDouble(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.1)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleTile extends StatelessWidget {
  const VehicleTile({super.key, required this.vehicle, required this.onTap});
  final AdminVehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = statusStyle(vehicle.isActive ? vehicle.status : 'no_data');
    return NeuCard(
      onTap: onTap,
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: s.color.withAlpha(38), borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.directions_bus_rounded, color: s.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle.code, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text(
                  '${vehicle.routeName}${vehicle.plateNumber.isEmpty ? '' : ' · ${vehicle.plateNumber}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                Row(
                  children: [
                    Text('${vehicle.userCount} rider${vehicle.userCount == 1 ? '' : 's'}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    const Text('  ·  ', style: TextStyle(color: AppColors.muted)),
                    LiveAgo(
                      time: vehicle.lastSeen,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (vehicle.isActive)
                StatusChip(vehicle.status)
              else
                const Text('Inactive',
                    style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
              if (vehicle.isActive && vehicle.speed != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${vehicle.speed!.round()} km/h',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Wrap of choice chips used instead of dropdowns for route / vehicle pickers.
class ChipPicker<T> extends StatelessWidget {
  const ChipPicker({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.emptyText = 'Nothing to choose from',
  });

  final String label;
  final List<MapEntry<T, String>> options;
  final T? selected;
  final ValueChanged<T?> onChanged;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 8),
        if (options.isEmpty)
          Text(emptyText, style: const TextStyle(color: AppColors.muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in options)
                ChoiceChip(
                  label: Text(o.value),
                  selected: o.key == selected,
                  showCheckmark: false,
                  selectedColor: AppColors.terracotta,
                  backgroundColor: AppColors.sand,
                  labelStyle: TextStyle(
                    color: o.key == selected ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => onChanged(o.key == selected ? null : o.key),
                ),
            ],
          ),
      ],
    );
  }
}

/// Centers admin content and caps its width on large screens.
class AdminBody extends StatelessWidget {
  const AdminBody({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: child),
    );
  }
}

class SheetButtons extends StatelessWidget {
  const SheetButtons({super.key, required this.label, required this.busy, required this.onSave});
  final String label;
  final bool busy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) =>
      GradientButton(label: label, busy: busy, onPressed: busy ? null : onSave);
}
