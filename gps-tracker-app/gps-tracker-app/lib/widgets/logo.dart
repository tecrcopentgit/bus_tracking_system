import 'package:flutter/material.dart';

/// App logo (bus + route pins) and the bus-only sprite used in scenes.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.width = 160});
  final double width;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/logo.png', width: width, fit: BoxFit.contain);
}

class BusSprite extends StatelessWidget {
  const BusSprite({super.key, this.width = 200});
  final double width;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/bus.png', width: width, fit: BoxFit.contain);
}
