import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations.dart';
import '../../widgets/buttons.dart';
import '../../widgets/logo.dart';

/// Admin sign-in: dark console look, no sign-up. Non-admin accounts are refused.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().login(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.charcoal),
        child: Stack(
          children: [
            Positioned(
              right: -90,
              top: -70,
              child: Container(
                width: 280,
                height: 280,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.terracotta),
              ),
            ),
            Positioned(
              left: -60,
              bottom: -90,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(14)),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: FadeSlideIn(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: darkShadow,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(child: Bobbing(amplitude: 4, child: AppLogo(width: 130))),
                              const SizedBox(height: 10),
                              const Text('Admin Console',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                              const Text('Manage users, buses and routes',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.muted)),
                              const SizedBox(height: 22),
                              if (auth.error != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.pink.withAlpha(28),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.pink.withAlpha(90)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: AppColors.pink),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(auth.error!)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                enabled: !auth.busy,
                                decoration: const InputDecoration(
                                    labelText: 'Admin email', prefixIcon: Icon(Icons.admin_panel_settings_outlined)),
                                validator: (v) => (v == null || !v.contains('@')) ? 'Enter your email' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                enabled: !auth.busy,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                              ),
                              const SizedBox(height: 22),
                              GradientButton(
                                label: 'Sign in',
                                icon: Icons.login_rounded,
                                busy: auth.busy,
                                onPressed: auth.busy ? null : _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
