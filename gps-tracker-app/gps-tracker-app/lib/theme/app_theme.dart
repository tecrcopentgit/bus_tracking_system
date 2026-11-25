import 'package:flutter/material.dart';

/// Warm "desert sunset" palette (sand, terracotta, charcoal) with the logo's
/// sky-blue and pink used only for small accents.
class AppColors {
  static const sand = Color(0xFFEFE7DE);
  static const cream = Color(0xFFF8F2EB);
  static const terracotta = Color(0xFFC95A2E);
  static const terracottaLight = Color(0xFFE98B5E);
  static const terracottaDeep = Color(0xFF9A3B19);
  static const charcoal = Color(0xFF2B2A29);
  static const charcoalSoft = Color(0xFF3B3937);
  static const ink = Color(0xFF3A2A22);
  static const muted = Color(0xFF8C7C70);
  static const line = Color(0xFFE2D6CA);
  static const sky = Color(0xFF2BB8DA);
  static const pink = Color(0xFFE8365D);
  static const green = Color(0xFF4C9A3B);
  static const amber = Color(0xFFE59A1B);
}

class AppGradients {
  static const terracotta = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.terracottaLight, AppColors.terracotta, AppColors.terracottaDeep],
  );
  static const charcoal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A3837), Color(0xFF1F1E1D)],
  );
  static const dusk = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7D2AB), Color(0xFFEE9A6B), Color(0xFFC95A2E)],
  );
}

/// Soft "pressed-out" look: warm drop shadow bottom-right, white highlight top-left.
const List<BoxShadow> neuShadow = [
  BoxShadow(color: Color(0x2E765238), blurRadius: 22, offset: Offset(8, 12)),
  BoxShadow(color: Color(0xCCFFFFFF), blurRadius: 16, offset: Offset(-6, -6)),
];

const List<BoxShadow> darkShadow = [
  BoxShadow(color: Color(0x59000000), blurRadius: 26, offset: Offset(0, 14)),
];

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.terracotta,
    primary: AppColors.terracotta,
    secondary: AppColors.sky,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: c, width: w),
      );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.sand,
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cream,
      labelStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: border(AppColors.line, 1),
      enabledBorder: border(AppColors.line, 1),
      focusedBorder: border(AppColors.terracotta, 1.8),
      errorBorder: border(AppColors.pink, 1.2),
      focusedErrorBorder: border(AppColors.pink, 1.8),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.terracotta),
    ),
  );
}
