import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/token_storage.dart';
import 'providers/auth_provider.dart';
import 'providers/nav_controller.dart';
import 'providers/tracking_provider.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final tokens = TokenStorage();
  final api = ApiClient(tokens);
  runApp(BusTrackerApp(api: api, tokens: tokens));
}

class BusTrackerApp extends StatelessWidget {
  const BusTrackerApp({super.key, required this.api, required this.tokens});

  final ApiClient api;
  final TokenStorage tokens;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(api, tokens)..restoreSession(),
        ),
      ],
      child: MaterialApp(
        title: 'Bus Tracker',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AuthGate(),
      ),
    );
  }
}

/// Splash -> Login -> App, cross-fading between them. The tracking state lives
/// *inside* the signed-in branch, so logging out (or a 401) disposes it and
/// stops all polling; a different user always starts clean.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final Widget screen;

    switch (auth.status) {
      case AuthStatus.unknown:
        screen = const SplashScreen(key: ValueKey('splash'));
        break;
      case AuthStatus.unauthenticated:
        // If the session expired while a pushed page (e.g. register) was open, drop back to root.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
        });
        screen = const LoginScreen(key: ValueKey('login'));
        break;
      case AuthStatus.authenticated:
        screen = MultiProvider(
          key: ValueKey('app-${auth.user!.id}'),
          providers: [
            ChangeNotifierProvider<TrackingProvider>(
              create: (ctx) => TrackingProvider(ctx.read<ApiClient>())..load(),
            ),
            ChangeNotifierProvider<NavController>(create: (_) => NavController()),
          ],
          child: const AppShell(),
        );
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      switchInCurve: Curves.easeOutCubic,
      child: screen,
    );
  }
}
