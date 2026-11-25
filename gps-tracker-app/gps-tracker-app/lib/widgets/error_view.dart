import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'animations.dart';
import 'buttons.dart';
import 'logo.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Bobbing(
                child: Opacity(opacity: 0.55, child: const AppLogo(width: 190)),
              ),
              const SizedBox(height: 22),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.4, color: AppColors.ink),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 190,
                child: GradientButton(label: 'Try again', icon: Icons.refresh_rounded, onPressed: onRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Bobbing(child: AppLogo(width: 170)),
          SizedBox(height: 22),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              minHeight: 5,
              color: AppColors.terracotta,
              backgroundColor: AppColors.line,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          SizedBox(height: 12),
          Text('Finding your bus…', style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
