// ignore_for_file: experimental_member_use
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/player/presentation/providers/player_provider.dart';
import '../dsp/dynamic_loudness_controller.dart';
import 'audio_telemetry.dart';

/// Stream provider for detecting active OS audio output device route (Speaker, Headset, Bluetooth, USB DAC).
final audioDevicesStreamProvider = StreamProvider<Set<AudioDevice>>((ref) async* {
  final session = await AudioSession.instance;
  yield await session.getDevices();
  yield* session.devicesStream;
});

/// Riverpod provider for active Audio Hardware Telemetry.
final audioTelemetryProvider = Provider<AudioTelemetry>((ref) {
  final loudnessState = ref.watch(dynamicLoudnessProvider);
  final devicesAsync = ref.watch(audioDevicesStreamProvider);
  final currentItemAsync = ref.watch(currentMediaItemProvider);

  final activeDevices = devicesAsync.value ?? <AudioDevice>{};
  final routeName = _formatDeviceRoute(activeDevices);

  final mediaItem = currentItemAsync.value;

  final format = (mediaItem?.extras?['format'] as String?)?.toUpperCase() ?? 'FLAC';
  final sampleRate = (mediaItem?.extras?['sampleRate'] as int?) ?? 44100;
  final bitDepth = (mediaItem?.extras?['bitDepth'] as int?) ?? 16;
  final bitrate = (mediaItem?.extras?['bitrate'] as int?) ?? 1411;

  // Standard Android AudioFlinger output sample rate
  const int defaultOutputSampleRate = 48000;
  final bool isResampled = sampleRate != defaultOutputSampleRate;

  return AudioTelemetry(
    sourceFormat: format,
    sampleRate: sampleRate,
    bitDepth: bitDepth,
    bitrate: bitrate,
    outputSampleRate: defaultOutputSampleRate,
    isResampled: isResampled,
    appliedGainDb: -1.5, // Default pre-amp headroom
    loudnessCompensationDb: loudnessState.lowShelfGainDb,
    audioSinkRoute: routeName,
  );
});

String _formatDeviceRoute(Set<AudioDevice> devices) {
  if (devices.isEmpty) return 'Internal Speaker';

  final types = devices.map((d) => d.type).toSet();

  if (types.contains(AudioDeviceType.bluetoothA2dp) ||
      types.contains(AudioDeviceType.bluetoothSco) ||
      types.contains(AudioDeviceType.bluetoothLe)) {
    return 'Bluetooth A2DP Output';
  }
  if (types.contains(AudioDeviceType.usbAudio)) {
    return 'USB High-Res DAC';
  }
  if (types.contains(AudioDeviceType.wiredHeadphones) ||
      types.contains(AudioDeviceType.wiredHeadset)) {
    return 'Wired Headphones (3.5mm)';
  }
  if (types.contains(AudioDeviceType.builtInSpeaker)) {
    return 'Internal Phone Speaker';
  }

  final first = devices.first;
  return first.name.isNotEmpty ? first.name : 'Android AudioFlinger Sink';
}
