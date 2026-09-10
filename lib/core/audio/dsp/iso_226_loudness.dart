import 'biquad_filter.dart';

/// Represents the dynamic equal-loudness state based on ISO 226 equal-loudness contours.
class LoudnessState {
  final double volumeLevel;
  final double lowShelfGainDb;
  final double highShelfGainDb;
  final bool isActive;

  const LoudnessState({
    required this.volumeLevel,
    required this.lowShelfGainDb,
    required this.highShelfGainDb,
    required this.isActive,
  });

  @override
  String toString() {
    return 'LoudnessState(vol: ${(volumeLevel * 100).toStringAsFixed(0)}%, lowShelf: +${lowShelfGainDb.toStringAsFixed(1)}dB, highShelf: +${highShelfGainDb.toStringAsFixed(1)}dB, active: $isActive)';
  }
}

/// Dynamic Fletcher-Munson Loudness Equalizer implementation following ISO 226 contours.
class Iso226LoudnessEqualizer {
  /// Low volume threshold (<= 40% volume: maximum dynamic compensation)
  static const double lowVolumeThreshold = 0.40;

  /// High volume threshold (>= 75% volume: flat response)
  static const double flatVolumeThreshold = 0.75;

  /// Maximum bass boost at 100 Hz for low volumes (+6.0 dB)
  static const double maxLowShelfGainDb = 6.0;

  /// Maximum treble boost at 10 kHz for low volumes (+4.0 dB)
  static const double maxHighShelfGainDb = 4.0;

  /// Calculates dynamic gain offsets for low and high frequencies given a 0.0–1.0 volume level.
  static LoudnessState calculateLoudnessState(double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0);

    if (clampedVolume >= flatVolumeThreshold) {
      return LoudnessState(
        volumeLevel: clampedVolume,
        lowShelfGainDb: 0.0,
        highShelfGainDb: 0.0,
        isActive: false,
      );
    }

    if (clampedVolume <= lowVolumeThreshold) {
      return LoudnessState(
        volumeLevel: clampedVolume,
        lowShelfGainDb: maxLowShelfGainDb,
        highShelfGainDb: maxHighShelfGainDb,
        isActive: true,
      );
    }

    // Smooth linear interpolation between 40% (+6dB/+4dB) and 75% (0dB)
    final ratio = (flatVolumeThreshold - clampedVolume) / (flatVolumeThreshold - lowVolumeThreshold);
    final lowGain = maxLowShelfGainDb * ratio;
    final highGain = maxHighShelfGainDb * ratio;

    return LoudnessState(
      volumeLevel: clampedVolume,
      lowShelfGainDb: lowGain,
      highShelfGainDb: highGain,
      isActive: true,
    );
  }

  /// Creates Biquad Filters for low-shelf (100 Hz) and high-shelf (10 kHz) matching current state.
  static List<BiquadFilter> createFilters({
    required LoudnessState state,
    double sampleRate = 44100.0,
  }) {
    return [
      BiquadFilter(
        type: BiquadFilterType.lowShelf,
        frequency: 100.0,
        gainDb: state.lowShelfGainDb,
        sampleRate: sampleRate,
      ),
      BiquadFilter(
        type: BiquadFilterType.highShelf,
        frequency: 10000.0,
        gainDb: state.highShelfGainDb,
        sampleRate: sampleRate,
      ),
    ];
  }
}
