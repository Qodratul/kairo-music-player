import 'package:flutter/material.dart';
import 'color_palette.dart';

/// Typography design tokens supporting Sans-Serif and Tabular Monospace figures.
abstract class KairoTypography {
  // Primary Sans-Serif styles for UI text
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: KairoColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: KairoColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: KairoColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    color: KairoColors.textSecondary,
  );

  // Monospace / Tabular styles for Telemetry HUD, Bitrate, Sample Rate & Timestamps
  static const TextStyle telemetryTitle = TextStyle(
    fontFamily: 'monospace',
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 14.0,
    fontWeight: FontWeight.bold,
    color: KairoColors.primary,
    letterSpacing: 0.5,
  );

  static const TextStyle telemetryValue = TextStyle(
    fontFamily: 'monospace',
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 13.0,
    fontWeight: FontWeight.w500,
    color: KairoColors.textPrimary,
  );

  static const TextStyle telemetryLabel = TextStyle(
    fontFamily: 'monospace',
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 11.0,
    fontWeight: FontWeight.normal,
    color: KairoColors.textSecondary,
  );

  static const TextStyle timestamp = TextStyle(
    fontFamily: 'monospace',
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: KairoColors.textSecondary,
  );
}
