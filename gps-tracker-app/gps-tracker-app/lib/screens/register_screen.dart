import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/buttons.dart';
import '../widgets/logo.dart';
import '../widgets/painters.dart';
import '../widgets/pressable.dart';
import '../widgets/ticket.dart';

/// Register: designed as a boarding pass. A terracotta header with a barcode
/// is torn from the form by a perforated line and side notches.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const double _headerH = 124;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().register(_name.text, _email.text, _password.text);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(6),
          child: Pressable(
            onTap: () => Navigator.of(context).maybePop(),
            scale: 0.88,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
                boxShadow: neuShadow,
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 22),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: FadeSlideIn(
              dy: 0.1,
              child: PhysicalShape(
                color: AppColors.cream,
                elevation: 12,
                shadowColor: const Color(0x80765238),
                clipBehavior: Clip.antiAlias,
                clipper: PassClipper(notchY: _headerH),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(height: _headerH),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
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
                                _field(
                                  0,
                                  TextFormField(
                                    controller: _name,
                                    textCapitalization: TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    enabled: !auth.busy,
                                    decoration: const InputDecoration(
                                      labelText: 'Full name',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().length < 2) ? 'Enter your name' : null,
                                  ),
                                ),
                                _field(
                                  1,
                                  TextFormField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    enabled: !auth.busy,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.mail_outline_rounded),
                                    ),
                                    validator: (v) {
                                      final value = v?.trim() ?? '';
                                      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)
                                          ? null
                                          : 'Enter a valid email';
                                    },
                                  ),
                                ),
                                _field(
                                  2,
                                  TextFormField(
                                    controller: _password,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.next,
                                    enabled: !auth.busy,
                                    decoration: InputDecoration(
                                      labelText: 'Password (min 8 characters)',
                                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscure
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded),
                                        onPressed: () => setState(() => _obscure = !_obscure),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.length < 8) return 'At least 8 characters';
                                      if (v.length > 72) return 'At most 72 characters';
                                      return null;
                                    },
                                  ),
                                ),
                                _field(
                                  3,
                                  TextFormField(
                                    controller: _confirm,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    enabled: !auth.busy,
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: const InputDecoration(
                                      labelText: 'Confirm password',
                                      prefixIcon: Icon(Icons.lock_reset_rounded),
                                    ),
                                    validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FadeSlideIn(
                                  delay: const Duration(milliseconds: 650),
                                  child: GradientButton(
                                    label: 'Get my pass',
                                    icon: Icons.confirmation_number_outlined,
                                    busy: auth.busy,
                                    onPressed: auth.busy ? null : _submit,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'After signing up, an administrator assigns your bus route and vehicle.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // perforation
                    Positioned(
                      top: _headerH - 1,
                      left: 20,
                      right: 20,
                      height: 2,
                      child: CustomPaint(painter: DashedLinePainter(color: Colors.white.withAlpha(200))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(int i, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: FadeSlideIn(delay: Duration(milliseconds: 250 + i * 90), child: child),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 1. Use minHeight instead of fixed height so it can grow if system font scaling is large
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      decoration: const BoxDecoration(gradient: AppGradients.terracotta),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(20),
              boxShadow: darkShadow,
            ),
            child: const Bobbing(amplitude: 3, child: AppLogo(width: 62)),
          ),
          const SizedBox(width: 16), // Slightly tighter gap gives text more room
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'BUS PASS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                SizedBox(height: 2),
                // 2. FittedBox scales down 'New passenger' slightly on narrow screens so it stays on 1 line
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'New passenger',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  'Create your account',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: CustomPaint(
              painter: BarcodePainter(seed: 'new-passenger', color: const Color(0xCC2B1409)),
            ),
          ),
        ],
      ),
    );
  }

}