import 'package:flutter/material.dart';

/// Audiophile High-Contrast Dark-Mode Color Palette.
abstract class KairoColors {
  // Backgrounds
  static const Color background = Color(0xFF0D0D11);
  static const Color surface = Color(0xFF16161E);
  static const Color surfaceElevated = Color(0xFF20202C);
  static const Color surfaceBorder = Color(0xFF2A2A38);

  // Accents (Audiophile High-Contrast)
  static const Color primary = Color(0xFF00E5FF); // Neon Cyan
  static const Color primaryMuted = Color(0xFF00B0FF);
  static const Color secondary = Color(0xFFFFB300); // Warm Gold / Amber
  static const Color accentGreen = Color(0xFF00E676); // Emerald Green
  static const Color accentRed = Color(0xFFFF1744); // Signal Red

  // Text Colors
  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0xFF9E9EA8);
  static const Color textMuted = Color(0xFF626270);

  // Telemetry HUD / Visualizer Overlay
  static const Color hudBackground = Color(0xDC09090D);
  static const Color hudBorder = Color(0xFF00E5FF);
}
