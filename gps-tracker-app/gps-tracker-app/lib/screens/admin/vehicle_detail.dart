import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_common.dart';
import '../../widgets/animations.dart';
import '../../widgets/status_chip.dart';

/// Bottom sheet with a vehicle's live details and its latest GPS fixes.
void showVehicleDetail(BuildContext pageContext, AdminProvider admin, AdminVehicle v) {
  showAdminSheet<void>(pageContext, title: v.code, child: _VehicleDetail(vehicle: v, admin: admin));
}

class _VehicleDetail extends StatefulWidget {
  const _VehicleDetail({required this.vehicle, required this.admin});
  final AdminVehicle vehicle;
  final AdminProvider admin;

  @override
  State<_VehicleDetail> createState() => _VehicleDetailState();
}

class _VehicleDetailState extends State<_VehicleDetail> {
  late final Future<List<HistoryPoint>> _history = widget.admin.vehicleHistory(widget.vehicle.id, limit: 8);

  Widget _row(String k, Widget v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(child: Text(k, style: const TextStyle(color: AppColors.muted))),
            v,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    const bold = TextStyle(fontWeight: FontWeight.w700);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Status', v.isActive ? StatusChip(v.status) : const Text('Inactive', style: bold)),
        _row('Route', Text(v.routeName, style: bold)),
        _row('Plate', Text(v.plateNumber.isEmpty ? '—' : v.plateNumber, style: bold)),
        _row('Riders assigned', Text('${v.userCount}', style: bold)),
        _row('Speed', Text(v.speed == null ? '—' : '${v.speed!.toStringAsFixed(1)} km/h', style: bold)),
        _row(
          'Position',
          Text(v.hasFix ? '${v.latitude!.toStringAsFixed(5)}, ${v.longitude!.toStringAsFixed(5)}' : 'No GPS yet',
              style: bold),
        ),
        _row('Last GPS fix', LiveAgo(time: v.lastSeen, style: bold)),
        const SizedBox(height: 14),
        const Text('Recent GPS fixes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        FutureBuilder<List<HistoryPoint>>(
          future: _history,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
              );
            }
            if (snap.hasError) {
              return const Text('Could not load history.', style: TextStyle(color: AppColors.pink));
            }
            final pts = (snap.data ?? const <HistoryPoint>[]).reversed.toList();
            if (pts.isEmpty) {
              return const Text('No GPS data received yet.', style: TextStyle(color: AppColors.muted));
            }
            return Column(
              children: [
                for (final p in pts)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(formatClock(p.recordedAt), style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
                        const Spacer(),
                        Text('${p.speed.round()} km/h  ·  ${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
