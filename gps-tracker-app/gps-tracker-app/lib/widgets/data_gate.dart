import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/tracking_provider.dart';
import 'error_view.dart';

/// Shows loading / error states until the route + vehicle are available,
/// then builds the real page.
class DataGate extends StatelessWidget {
  const DataGate({super.key, required this.builder});

  final Widget Function(BuildContext context, TrackingProvider t, RouteInfo route, Vehicle vehicle)
      builder;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TrackingProvider>();
    if (t.loading && t.route == null) return const SafeArea(child: LoadingView());
    if (t.error != null || t.route == null || t.vehicle == null) {
      return SafeArea(
        child: ErrorView(message: t.error ?? 'Unable to load your route.', onRetry: t.load),
      );
    }
    return builder(context, t, t.route!, t.vehicle!);
  }
}
