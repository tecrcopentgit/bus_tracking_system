import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_models.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_common.dart';
import '../../widgets/animations.dart';
import '../../widgets/error_view.dart';
import 'vehicle_detail.dart';

class VehiclesPage extends StatelessWidget {
  const VehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminProvider>();
    if (a.loading && a.overview == null) return const LoadingView();
    if (a.error != null) return ErrorView(message: a.error!, onRetry: a.load);
    final vehicles = a.vehicles;

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.terracotta,
          onRefresh: a.refreshAll,
          child: AdminBody(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                AdminHeader(
                  title: 'Vehicles',
                  subtitle: '${vehicles.length} buses · tap one for live details',
                  onRefresh: a.refreshAll,
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < vehicles.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FadeSlideIn(
                      delay: Duration(milliseconds: 50 * (i > 10 ? 10 : i)),
                      child: Row(
                        children: [
                          Expanded(
                            child: VehicleTile(
                              vehicle: vehicles[i],
                              onTap: () => showVehicleDetail(context, a, vehicles[i]),
                            ),
                          ),
                          const SizedBox(width: 10),
                          RoundActionButton(
                            icon: Icons.edit_rounded,
                            tooltip: 'Edit vehicle',
                            onTap: () => showAdminSheet<void>(
                              context,
                              title: 'Edit ${vehicles[i].code}',
                              child: _VehicleEditor(admin: a, vehicle: vehicles[i], pageContext: context),
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
        Positioned(
          right: 20,
          bottom: 20,
          child: AddFab(
            label: 'Add vehicle',
            onTap: () => showAdminSheet<void>(
              context,
              title: 'New vehicle',
              child: _VehicleEditor(admin: a, pageContext: context),
            ),
          ),
        ),
      ],
    );
  }
}

class RoundActionButton extends StatelessWidget {
  const RoundActionButton({super.key, required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(color: AppColors.cream, shape: BoxShape.circle, boxShadow: neuShadow),
            child: Icon(icon, size: 21, color: AppColors.terracotta),
          ),
        ),
      );
}

class _VehicleEditor extends StatefulWidget {
  const _VehicleEditor({required this.admin, required this.pageContext, this.vehicle});
  final AdminProvider admin;
  final BuildContext pageContext;
  final AdminVehicle? vehicle;

  @override
  State<_VehicleEditor> createState() => _VehicleEditorState();
}

class _VehicleEditorState extends State<_VehicleEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.vehicle?.code ?? '');
  late final _plate = TextEditingController(text: widget.vehicle?.plateNumber ?? '');
  late int? _route = widget.vehicle?.routeId;
  late bool _active = widget.vehicle?.isActive ?? true;
  bool _busy = false;

  bool get _creating => widget.vehicle == null;

  @override
  void dispose() {
    _code.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_route == null) {
      showMessage(widget.pageContext, 'Choose a route for this vehicle', error: true);
      return;
    }
    final a = widget.admin;
    final v = widget.vehicle;
    setState(() => _busy = true);
    final ok = await runAction(widget.pageContext, () async {
      if (_creating) {
        await a.createVehicle(_code.text.trim(), _plate.text.trim(), _route!);
      } else {
        final changes = <String, dynamic>{};
        if (_plate.text.trim() != v!.plateNumber) changes['plate_number'] = _plate.text.trim();
        if (_route != v.routeId) changes['route_id'] = _route;
        if (_active != v.isActive) changes['is_active'] = _active;
        if (changes.isNotEmpty) await a.updateVehicle(v.id, changes);
      }
    }, success: _creating ? 'Vehicle added' : 'Vehicle updated');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _code,
            enabled: _creating,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Vehicle code (the ID the GPS device sends)',
              prefixIcon: Icon(Icons.tag_rounded),
            ),
            validator: (v) => RegExp(r'^[A-Za-z0-9_\-]{2,50}$').hasMatch(v?.trim() ?? '')
                ? null
                : 'Use letters, numbers, - or _',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Plate number', prefixIcon: Icon(Icons.pin_outlined)),
          ),
          const SizedBox(height: 16),
          ChipPicker<int>(
            label: 'Route',
            options: [for (final r in widget.admin.routes) MapEntry(r.id, r.name)],
            selected: _route,
            onChanged: (v) => setState(() => _route = v),
          ),
          if (!_creating) ...[
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Inactive vehicles stop accepting GPS data'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
          ],
          const SizedBox(height: 20),
          SheetButtons(label: _creating ? 'Add vehicle' : 'Save changes', busy: _busy, onSave: _save),
        ],
      ),
    );
  }
}
