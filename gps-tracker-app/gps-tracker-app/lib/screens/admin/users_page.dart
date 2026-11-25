import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_common.dart';
import '../../widgets/animations.dart';
import '../../widgets/error_view.dart';
import '../../widgets/neu_card.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _edit(BuildContext context, AdminProvider a, AdminUser u) {
    showAdminSheet<void>(context, title: 'Edit user', child: _UserEditor(user: u, admin: a, pageContext: context));
  }

  void _create(BuildContext context, AdminProvider a) {
    showAdminSheet<void>(context, title: 'New user', child: _UserEditor(admin: a, pageContext: context));
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminProvider>();
    if (a.loading && a.overview == null) return const LoadingView();
    if (a.error != null) return ErrorView(message: a.error!, onRetry: a.load);

    final q = _search.text.trim().toLowerCase();
    final users = a.users
        .where((u) => q.isEmpty || u.fullName.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
        .toList();

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
                  title: 'Users',
                  subtitle: '${a.users.length} accounts · ${a.overview?.unassignedUsers ?? 0} waiting for a bus',
                  onRefresh: a.refreshAll,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search name or email',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                if (users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text('No users match.', style: TextStyle(color: AppColors.muted))),
                  ),
                for (var i = 0; i < users.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FadeSlideIn(
                      delay: Duration(milliseconds: 40 * (i > 12 ? 12 : i)),
                      child: _UserTile(user: users[i], onTap: () => _edit(context, a, users[i])),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: AddFab(label: 'Add user', onTap: () => _create(context, a)),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withAlpha(40), borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onTap});
  final AdminUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      onTap: onTap,
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: user.isAdmin ? AppGradients.charcoal : AppGradients.terracotta,
              shape: BoxShape.circle,
            ),
            child: Text(user.fullName.isEmpty ? '?' : user.fullName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                    ),
                    if (user.isAdmin) const _Tag('ADMIN', AppColors.charcoal),
                    if (!user.isActive) const _Tag('INACTIVE', AppColors.pink),
                  ],
                ),
                Text(user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  user.assigned ? '${user.routeName} · ${user.vehicleCode}' : (user.isAdmin ? 'Administrator' : 'No bus assigned'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: user.assigned ? AppColors.terracotta : (user.isAdmin ? AppColors.muted : AppColors.amber),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

/// Create (user == null) or edit a user, including route/vehicle assignment.
class _UserEditor extends StatefulWidget {
  const _UserEditor({this.user, required this.admin, required this.pageContext});
  final AdminUser? user;
  final AdminProvider admin;
  final BuildContext pageContext;

  @override
  State<_UserEditor> createState() => _UserEditorState();
}

class _UserEditorState extends State<_UserEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?.fullName ?? '');
  late final _email = TextEditingController(text: widget.user?.email ?? '');
  final _password = TextEditingController();
  late bool _active = widget.user?.isActive ?? true;
  late bool _isAdmin = widget.user?.isAdmin ?? false;
  late int? _route = widget.user?.routeId;
  late int? _vehicle = widget.user?.vehicleId;
  bool _busy = false;

  bool get _creating => widget.user == null;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final a = widget.admin;
    final u = widget.user;
    setState(() => _busy = true);
    final ok = await runAction(widget.pageContext, () async {
      if (_creating) {
        if ((_route == null) != (_vehicle == null)) {
          throw ApiException('Pick both a route and a vehicle, or neither.');
        }
        await a.createUser(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          isAdmin: _isAdmin,
          routeId: _route,
          vehicleId: _vehicle,
        );
        return;
      }
      final changes = <String, dynamic>{};
      if (_name.text.trim() != u!.fullName) changes['full_name'] = _name.text.trim();
      if (_active != u.isActive) changes['is_active'] = _active;
      if (_isAdmin != u.isAdmin) changes['is_admin'] = _isAdmin;
      if (_password.text.isNotEmpty) changes['password'] = _password.text;
      if (changes.isNotEmpty) await a.updateUser(u.id, changes);
      if (_route != u.routeId || _vehicle != u.vehicleId) {
        if (_route != null && _vehicle != null) {
          await a.assign(u.id, _route!, _vehicle!);
        } else if (_route == null && _vehicle == null) {
          await a.unassign(u.id);
        } else {
          throw ApiException('Pick both a route and a vehicle, or clear both.');
        }
      }
    }, success: _creating ? 'User created' : 'User updated');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.admin;
    final vehicles = a.vehicles.where((v) => v.routeId == _route && v.isActive).toList();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.badge_outlined)),
            validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a name' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _email,
            enabled: _creating,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
            validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '') ? null : 'Enter a valid email',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: _creating ? 'Password (min 8 characters)' : 'New password (leave empty to keep)',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
            ),
            validator: (v) {
              final value = v ?? '';
              if (_creating && value.length < 8) return 'At least 8 characters';
              if (value.isNotEmpty && (value.length < 8 || value.length > 72)) return '8 to 72 characters';
              return null;
            },
          ),
          const SizedBox(height: 8),
          if (!_creating)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Account active', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Inactive users cannot sign in'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Administrator', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Can use the admin console'),
            value: _isAdmin,
            onChanged: (v) => setState(() => _isAdmin = v),
          ),
          const SizedBox(height: 6),
          ChipPicker<int>(
            label: 'Route',
            options: [for (final r in a.routes) MapEntry(r.id, r.name)],
            selected: _route,
            onChanged: (v) => setState(() {
              _route = v;
              _vehicle = null;
            }),
          ),
          const SizedBox(height: 14),
          ChipPicker<int>(
            label: 'Vehicle',
            emptyText: _route == null ? 'Choose a route first' : 'No active vehicles on this route',
            options: [for (final v in vehicles) MapEntry(v.id, v.code)],
            selected: _vehicle,
            onChanged: (v) => setState(() => _vehicle = v),
          ),
          const SizedBox(height: 22),
          SheetButtons(label: _creating ? 'Create user' : 'Save changes', busy: _busy, onSave: _save),
        ],
      ),
    );
  }
}
