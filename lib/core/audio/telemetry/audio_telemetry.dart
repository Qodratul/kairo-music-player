/// Telemetry data model for audio playback pipeline, hardware sink, and DSP metrics.
class AudioTelemetry {
  final String sourceFormat;
  final int sampleRate;
  final int bitDepth;
  final int bitrate;
  final int outputSampleRate;
  final bool isResampled;
  final double appliedGainDb;
  final double loudnessCompensationDb;
  final String audioSinkRoute;

  const AudioTelemetry({
    required this.sourceFormat,
    required this.sampleRate,
    required this.bitDepth,
    required this.bitrate,
    required this.outputSampleRate,
    required this.isResampled,
    required this.appliedGainDb,
    required this.loudnessCompensationDb,
    required this.audioSinkRoute,
  });

  factory AudioTelemetry.empty() {
    return const AudioTelemetry(
      sourceFormat: 'PCM',
      sampleRate: 44100,
      bitDepth: 16,
      bitrate: 320,
      outputSampleRate: 48000,
      isResampled: true,
      appliedGainDb: 0.0,
      loudnessCompensationDb: 0.0,
      audioSinkRoute: 'Internal Speaker',
    );
  }

  AudioTelemetry copyWith({
    String? sourceFormat,
    int? sampleRate,
    int? bitDepth,
    int? bitrate,
    int? outputSampleRate,
    bool? isResampled,
    double? appliedGainDb,
    double? loudnessCompensationDb,
    String? audioSinkRoute,
  }) {
    return AudioTelemetry(
      sourceFormat: sourceFormat ?? this.sourceFormat,
      sampleRate: sampleRate ?? this.sampleRate,
      bitDepth: bitDepth ?? this.bitDepth,
      bitrate: bitrate ?? this.bitrate,
      outputSampleRate: outputSampleRate ?? this.outputSampleRate,
      isResampled: isResampled ?? this.isResampled,
      appliedGainDb: appliedGainDb ?? this.appliedGainDb,
      loudnessCompensationDb:
          loudnessCompensationDb ?? this.loudnessCompensationDb,
      audioSinkRoute: audioSinkRoute ?? this.audioSinkRoute,
    );
  }

  @override
  String toString() {
    return 'AudioTelemetry(format: $sourceFormat, $sampleRate Hz, $bitDepth-bit, $bitrate kbps, output: $outputSampleRate Hz [resampled: $isResampled], gain: ${appliedGainDb.toStringAsFixed(1)} dB, loudness: +${loudnessCompensationDb.toStringAsFixed(1)} dB, route: $audioSinkRoute)';
  }
}
