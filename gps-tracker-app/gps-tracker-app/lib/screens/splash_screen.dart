import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/logo.dart';
import '../widgets/painters.dart';

/// Intro: logo pops in, the title fades up, and a bus drives along a dashed
/// road at the bottom while the session is restored.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  late final AnimationController _drive =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void dispose() {
    _intro.dispose();
    _drive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pop = CurvedAnimation(parent: _intro, curve: Curves.elasticOut);
    final fade = CurvedAnimation(parent: _intro, curve: const Interval(0.45, 1, curve: Curves.easeOut));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.dusk),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _drive,
                builder: (_, __) => CustomPaint(painter: RoadScenePainter(_drive.value)),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: pop,
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: darkShadow,
                      ),
                      child: Bobbing(amplitude: 5, child: AppLogo(width: size.width * 0.5)),
                    ),
                  ),
                  const SizedBox(height: 26),
                  FadeTransition(
                    opacity: fade,
                    child: Column(
                      children: const [
                        Text(
                          'Bus Tracker',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Know exactly where your ride is',
                          style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: size.height * 0.035,
              child: FadeTransition(
                opacity: fade,
                child: const Center(
                  child: Text(
                    'Getting things ready…',
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, letterSpacing: 0.4),
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
