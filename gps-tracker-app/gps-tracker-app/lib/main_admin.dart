import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/token_storage.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'theme/app_theme.dart';
import 'widgets/animations.dart';
import 'widgets/logo.dart';

/// Admin Console entry point:  flutter run -t lib/main_admin.dart
/// (the rider app is lib/main.dart). Both share the same code and backend.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // A different storage key so the admin and rider apps never share a session.
  final tokens = TokenStorage(key: 'admin_access_token');
  final api = ApiClient(tokens);
  runApp(AdminApp(api: api, tokens: tokens));
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.api, required this.tokens});

  final ApiClient api;
  final TokenStorage tokens;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            api,
            tokens,
            requireAdmin: true,
            minSplash: const Duration(milliseconds: 900),
          )..restoreSession(),
        ),
      ],
      child: MaterialApp(
        title: 'Bus Tracker Admin',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _AdminGate(),
      ),
    );
  }
}

class _AdminGate extends StatelessWidget {
  const _AdminGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final Widget screen;

    switch (auth.status) {
      case AuthStatus.unknown:
        screen = const Scaffold(
          key: ValueKey('splash'),
          backgroundColor: AppColors.charcoal,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Bobbing(child: AppLogo(width: 150)),
                SizedBox(height: 18),
                Text('Admin Console',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        );
        break;
      case AuthStatus.unauthenticated:
        screen = const AdminLoginScreen(key: ValueKey('login'));
        break;
      case AuthStatus.authenticated:
        screen = ChangeNotifierProvider<AdminProvider>(
          key: ValueKey('admin-${auth.user!.id}'),
          create: (ctx) => AdminProvider(ctx.read<ApiClient>())..load(),
          child: const AdminShell(),
        );
        break;
    }

    return AnimatedSwitcher(duration: const Duration(milliseconds: 500), child: screen);
  }
}
