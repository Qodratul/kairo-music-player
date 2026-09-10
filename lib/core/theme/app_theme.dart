import 'package:flutter/material.dart';

import 'color_palette.dart';
import 'typography.dart';

abstract class KairoTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: KairoColors.background,
      colorScheme: const ColorScheme.dark(
        surface: KairoColors.surface,
        surfaceContainerHighest: KairoColors.surfaceElevated,
        primary: KairoColors.primary,
        secondary: KairoColors.secondary,
        onSurface: KairoColors.textPrimary,
        onPrimary: KairoColors.background,
      ),
      textTheme: const TextTheme(
        titleLarge: KairoTypography.titleLarge,
        titleMedium: KairoTypography.titleMedium,
        bodyMedium: KairoTypography.bodyMedium,
        bodySmall: KairoTypography.bodySmall,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: KairoColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: KairoTypography.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: KairoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: KairoColors.surfaceBorder, width: 1),
        ),
      ),
    );
  }
}
