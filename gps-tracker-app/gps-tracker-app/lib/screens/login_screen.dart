import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/buttons.dart';
import '../widgets/logo.dart';
import '../widgets/painters.dart';
import '../widgets/route_transitions.dart';
import 'register_screen.dart';

/// Login: an animated desert-road scene up top (hills drift, road dashes
/// scroll, the bus rumbles) with the form on a cream sheet sliding over it.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  late final AnimationController _scene =
      AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();

  @override
  void dispose() {
    _scene.dispose();
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
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 80;
    final heroH = keyboardOpen ? 150.0 : math.max(250.0, math.min(340.0, media.size.height * 0.38));
    const anim = Duration(milliseconds: 380);
    final busWidth = math.max(110.0, math.min(240.0, heroH * 0.72));

    return Scaffold(
      backgroundColor: AppColors.sand,
      body: Stack(
        children: [
          AnimatedPositioned(
            duration: anim,
            curve: Curves.easeOutCubic,
            top: 0,
            left: 0,
            right: 0,
            height: heroH,
            child: Container(
              decoration: const BoxDecoration(gradient: AppGradients.dusk),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _scene,
                      builder: (_, __) => CustomPaint(painter: RoadScenePainter(_scene.value)),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Row(
                        children: const [
                          Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'BUS TRACKER',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: heroH * 0.1,
                    child: Center(
                      child: Bobbing(
                        amplitude: 2.2,
                        duration: const Duration(milliseconds: 420),
                        child: BusSprite(width: busWidth),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: anim,
            curve: Curves.easeOutCubic,
            top: heroH - 34,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.sand,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, -6))],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(26, 28, 26, 24 + media.viewInsets.bottom),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Welcome back',
                                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                                  SizedBox(height: 2),
                                  Text('Sign in to see your bus live',
                                      style: TextStyle(color: AppColors.muted, fontSize: 15)),
                                ],
                              ),
                            ),
                            const AppLogo(width: 74),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (auth.error != null) ...[
                        _ErrorBanner(message: auth.error!),
                        const SizedBox(height: 16),
                      ],
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          enabled: !auth.busy,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'Enter your email';
                            if (!value.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          enabled: !auth.busy,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  key: ValueKey(_obscure),
                                ),
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 400),
                        child: GradientButton(
                          label: 'Sign in',
                          icon: Icons.login_rounded,
                          busy: auth.busy,
                          onPressed: auth.busy ? null : _submit,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 500),
                        child: TextButton(
                          onPressed: auth.busy
                              ? null
                              : () => Navigator.of(context).push(fadeSlideRoute<void>(const RegisterScreen())),
                          child: const Text(
                            "New here? Create an account",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(scale: 0.9 + 0.1 * v, child: Opacity(opacity: math.max(0.0, math.min(1.0, v)), child: child)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.pink.withAlpha(28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.pink.withAlpha(90)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.pink),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: AppColors.ink, fontSize: 14))),
          ],
        ),
      ),
    );
  }
}
