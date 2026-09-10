import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/telemetry/telemetry_provider.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography.dart';

/// Telemetry HUD overlay widget for inspectable audio pipeline, hardware sink, and DSP metrics.
class TelemetryHUD extends ConsumerWidget {
  const TelemetryHUD({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(audioTelemetryProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: KairoColors.hudBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: KairoColors.hudBorder.withValues(alpha: 0.6),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: KairoColors.primary.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(
                Icons.developer_board,
                color: KairoColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'AUDIO HARDWARE TELEMETRY HUD',
                style: KairoTypography.telemetryTitle.copyWith(fontSize: 11),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: telemetry.isResampled
                      ? KairoColors.secondary
                      : KairoColors.accentGreen,
                ),
              ),
            ],
          ),
          const Divider(color: KairoColors.surfaceBorder, height: 12),

          // Specs Grid
          Row(
            children: [
              // Left Column: Source Format & Bitrate
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SOURCE FORMAT', style: KairoTypography.telemetryLabel),
                    const SizedBox(height: 2),
                    Text(
                      '${telemetry.sourceFormat} • ${(telemetry.sampleRate / 1000).toStringAsFixed(1)} kHz / ${telemetry.bitDepth}-bit',
                      style: KairoTypography.telemetryValue,
                    ),
                    const SizedBox(height: 6),
                    const Text('BITRATE', style: KairoTypography.telemetryLabel),
                    const SizedBox(height: 2),
                    Text(
                      '${telemetry.bitrate} kbps',
                      style: KairoTypography.telemetryValue,
                    ),
                  ],
                ),
              ),

              // Right Column: Pipeline Status & Output Sink
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PIPELINE SINK', style: KairoTypography.telemetryLabel),
                    const SizedBox(height: 2),
                    Text(
                      telemetry.audioSinkRoute,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KairoTypography.telemetryValue,
                    ),
                    const SizedBox(height: 6),
                    const Text('DSP & GAIN STAGING', style: KairoTypography.telemetryLabel),
                    const SizedBox(height: 2),
                    Text(
                      '${telemetry.appliedGainDb.toStringAsFixed(1)} dB | ISO 226: +${telemetry.loudnessCompensationDb.toStringAsFixed(1)} dB',
                      style: KairoTypography.telemetryValue.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Resampling Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: telemetry.isResampled
                  ? KairoColors.secondary.withValues(alpha: 0.1)
                  : KairoColors.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Row(
              children: [
                Icon(
                  telemetry.isResampled ? Icons.sync : Icons.verified,
                  size: 12,
                  color: telemetry.isResampled
                      ? KairoColors.secondary
                      : KairoColors.accentGreen,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    telemetry.isResampled
                        ? 'Resampled by Android AudioFlinger: ${telemetry.sampleRate} Hz → ${telemetry.outputSampleRate} Hz'
                        : 'Direct Native Stream (Bit-Perfect output)',
                    style: KairoTypography.telemetryLabel.copyWith(
                      fontSize: 10,
                      color: telemetry.isResampled
                          ? KairoColors.secondary
                          : KairoColors.accentGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
