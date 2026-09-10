import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biquad_filter.dart';
import 'iso_226_loudness.dart';

/// Riverpod Notifier for managing ISO 226 Fletcher-Munson dynamic loudness equalizer state.
class DynamicLoudnessNotifier extends Notifier<LoudnessState> {
  StreamSubscription<double>? _volumeSubscription;

  @override
  LoudnessState build() {
    ref.onDispose(() {
      _volumeSubscription?.cancel();
    });
    // Default initial volume state at 50%
    return Iso226LoudnessEqualizer.calculateLoudnessState(0.5);
  }

  /// Updates the current system hardware / player volume and recalculates loudness state.
  void updateVolume(double volume) {
    state = Iso226LoudnessEqualizer.calculateLoudnessState(volume);
  }

  /// Binds a real-time volume stream (e.g. from AudioPlayer or hardware volume listener).
  void attachVolumeStream(Stream<double> volumeStream) {
    _volumeSubscription?.cancel();
    _volumeSubscription = volumeStream.listen((volume) {
      updateVolume(volume);
    });
  }
}

/// Provider exposing the current [LoudnessState].
final dynamicLoudnessProvider =
    NotifierProvider<DynamicLoudnessNotifier, LoudnessState>(
  DynamicLoudnessNotifier.new,
);

/// Provider exposing active Biquad filters for ISO 226 equal-loudness contour compensation.
final loudnessFiltersProvider = Provider<List<BiquadFilter>>((ref) {
  final loudnessState = ref.watch(dynamicLoudnessProvider);
  return Iso226LoudnessEqualizer.createFilters(state: loudnessState);
});
