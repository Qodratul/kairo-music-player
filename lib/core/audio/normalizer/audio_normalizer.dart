import 'dart:math' as math;
import 'replay_gain.dart';

/// Target LUFS levels supported by KairoMP normalizer engine.
enum TargetLufs {
  /// Streaming Standard (-14 LUFS)
  streaming(-14.0),

  /// ReplayGain 2.0 / Audiophile Reference Standard (-18 LUFS)
  audiophile(-18.0);

  final double lufsValue;
  const TargetLufs(this.lufsValue);
}

/// Configuration options for audio gain normalization.
class NormalizationConfig {
  final TargetLufs targetLufs;
  final double preAmpHeadroomDb;
  final bool preferAlbumGain;

  const NormalizationConfig({
    this.targetLufs = TargetLufs.streaming,
    this.preAmpHeadroomDb = -1.5, // Mandatory -1.5 dBFS headroom per RULES.md
    this.preferAlbumGain = false,
  });
}

/// Result of a gain normalization calculation.
class NormalizationResult {
  final double appliedGainDb;
  final double linearVolumeScale;
  final bool isPeakLimited;
  final bool hasGainTag;

  const NormalizationResult({
    required this.appliedGainDb,
    required this.linearVolumeScale,
    required this.isPeakLimited,
    required this.hasGainTag,
  });

  @override
  String toString() {
    return 'NormalizationResult(appliedGainDb: ${appliedGainDb.toStringAsFixed(2)} dB, linearScale: ${linearVolumeScale.toStringAsFixed(4)}, peakLimited: $isPeakLimited, hasTag: $hasGainTag)';
  }
}

/// Engine for calculating ReplayGain 2.0 volume attenuation and peak limiting.
class AudioNormalizer {
  /// Reference loudness for ReplayGain 2.0 standard is -18.0 LUFS.
  static const double replayGainReferenceLufs = -18.0;

  /// Calculates the volume attenuation and linear scale factor for a given track.
  static NormalizationResult calculateGain({
    required ReplayGainData gainData,
    NormalizationConfig config = const NormalizationConfig(),
  }) {
    double? rawGainDb;
    double? peak;

    if (config.preferAlbumGain && gainData.hasAlbumGain) {
      rawGainDb = gainData.albumGainDb;
      peak = gainData.albumPeak ?? gainData.trackPeak;
    } else if (gainData.hasTrackGain) {
      rawGainDb = gainData.trackGainDb;
      peak = gainData.trackPeak;
    } else if (gainData.hasAlbumGain) {
      rawGainDb = gainData.albumGainDb;
      peak = gainData.albumPeak;
    }

    final bool hasTag = rawGainDb != null;

    // Headroom peak limit (e.g. -1.5 dBFS headroom -> linear limit ~0.8414)
    final double maxAllowedPeakDb = config.preAmpHeadroomDb;
    final double maxAllowedLinearPeak = math.pow(10, maxAllowedPeakDb / 20).toDouble();

    double totalGainDb;
    if (hasTag) {
      // Offset from ReplayGain 2.0 reference (-18 LUFS) to target LUFS (-14 or -18 LUFS)
      final double lufsOffset = config.targetLufs.lufsValue - replayGainReferenceLufs;
      totalGainDb = rawGainDb + lufsOffset + config.preAmpHeadroomDb;
    } else {
      // Fallback if no gain tag: apply pre-amp headroom (-1.5 dBFS)
      totalGainDb = config.preAmpHeadroomDb;
    }

    double linearScale = math.pow(10, totalGainDb / 20).toDouble();
    bool isPeakLimited = false;

    // Peak limiting / clipping prevention
    final double samplePeak = (peak != null && peak > 0) ? peak : 1.0;
    final double projectedPeak = linearScale * samplePeak;

    if (projectedPeak > maxAllowedLinearPeak) {
      linearScale = maxAllowedLinearPeak / samplePeak;
      totalGainDb = 20 * (math.log(linearScale) / math.ln10);
      isPeakLimited = true;
    }

    return NormalizationResult(
      appliedGainDb: totalGainDb,
      linearVolumeScale: linearScale,
      isPeakLimited: isPeakLimited,
      hasGainTag: hasTag,
    );
  }
}
