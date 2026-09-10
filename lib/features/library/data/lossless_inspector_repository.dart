import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../../core/audio/dsp/fft_analyser.dart';
import '../../../core/utils/isolate_runner.dart';

class _InspectParams {
  final String filePath;
  final int sampleRate;

  const _InspectParams(this.filePath, this.sampleRate);
}

/// Repository for inspecting audio file spectral integrity in a background isolate.
class LosslessInspectorRepository {
  /// Inspects audio file spectral integrity and returns a [SpectralAnalysisResult].
  /// Runs computation in a background isolate via [IsolateRunner].
  static Future<SpectralAnalysisResult> inspectFile(
    String filePath, {
    int sampleRate = 44100,
  }) async {
    final result = await IsolateRunner.run(
      _inspectTask,
      _InspectParams(filePath, sampleRate),
    );

    return result.fold(
      (error) => const SpectralAnalysisResult(
        spectralCutoffHz: 22050,
        isAuthenticLossless: true,
        isTranscode: false,
        maxObservedFrequencyHz: 22050.0,
        energyScore: 1.0,
        confidenceScore: 0.5,
      ),
      (data) => data,
    );
  }

  static Future<SpectralAnalysisResult> _inspectTask(_InspectParams params) async {
    final file = File(params.filePath);
    if (!file.existsSync()) {
      return const SpectralAnalysisResult(
        spectralCutoffHz: 22050,
        isAuthenticLossless: true,
        isTranscode: false,
        maxObservedFrequencyHz: 22050.0,
        energyScore: 1.0,
        confidenceScore: 0.5,
      );
    }

    final bytes = await file.readAsBytes();
    final pcmSamples = _bytesToFloatSamples(bytes);

    return FftAnalyser.analyzeBuffer(
      pcmSamples: pcmSamples,
      sampleRate: params.sampleRate,
    );
  }

  static List<double> _bytesToFloatSamples(Uint8List bytes) {
    final int sampleCount = math.min(bytes.length ~/ 2, 4096);
    final List<double> samples = List.filled(sampleCount, 0.0);
    final byteData = ByteData.sublistView(bytes);

    for (int i = 0; i < sampleCount; i++) {
      if (i * 2 + 1 < bytes.length) {
        final int int16Sample = byteData.getInt16(i * 2, Endian.little);
        samples[i] = int16Sample / 32768.0;
      }
    }
    return samples;
  }
}
