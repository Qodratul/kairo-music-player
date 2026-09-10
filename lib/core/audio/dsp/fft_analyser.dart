import 'dart:math' as math;

/// Complex number structure for FFT signal processing.
class Complex {
  final double real;
  final double imag;

  const Complex(this.real, [this.imag = 0.0]);

  Complex operator +(Complex other) => Complex(real + other.real, imag + other.imag);
  Complex operator -(Complex other) => Complex(real - other.real, imag - other.imag);
  Complex operator *(Complex other) => Complex(
        real * other.real - imag * other.imag,
        real * other.imag + imag * other.real,
      );

  double get magnitude => math.sqrt(real * real + imag * imag);
}

/// Results of audio spectral integrity analysis and transcode detection.
class SpectralAnalysisResult {
  final int spectralCutoffHz;
  final bool isAuthenticLossless;
  final bool isTranscode;
  final double maxObservedFrequencyHz;
  final double energyScore;
  final double confidenceScore;

  const SpectralAnalysisResult({
    required this.spectralCutoffHz,
    required this.isAuthenticLossless,
    required this.isTranscode,
    required this.maxObservedFrequencyHz,
    required this.energyScore,
    required this.confidenceScore,
  });

  @override
  String toString() {
    return 'SpectralAnalysisResult(cutoff: ${spectralCutoffHz}Hz, authentic: $isAuthenticLossless, transcode: $isTranscode, confidence: ${(confidenceScore * 100).toStringAsFixed(1)}%)';
  }
}

/// Fast Fourier Transform (FFT) Analyzer for detecting spectral frequency cutoffs and lossy transcode artifacts in FLAC files.
class FftAnalyser {
  /// Cooley-Tukey Radix-2 Fast Fourier Transform algorithm.
  static List<Complex> fft(List<Complex> x) {
    final int n = x.length;
    if (n <= 1) return x;

    if ((n & (n - 1)) != 0) {
      throw ArgumentError('FFT input length must be a power of 2, got $n');
    }

    final List<Complex> even = List.generate(n ~/ 2, (i) => x[2 * i]);
    final List<Complex> odd = List.generate(n ~/ 2, (i) => x[2 * i + 1]);

    final List<Complex> q = fft(even);
    final List<Complex> r = fft(odd);

    final List<Complex> y = List.filled(n, const Complex(0, 0));
    for (int k = 0; k < n ~/ 2; k++) {
      final double kth = -2 * k * math.pi / n;
      final Complex wk = Complex(math.cos(kth), math.sin(kth));
      y[k] = q[k] + wk * r[k];
      y[k + n ~/ 2] = q[k] - wk * r[k];
    }
    return y;
  }

  /// Analyzes a PCM audio sample buffer and returns spectral cutoff and lossy transcode detection metrics.
  static SpectralAnalysisResult analyzeBuffer({
    required List<double> pcmSamples,
    int sampleRate = 44100,
    int fftSize = 2048,
  }) {
    if (pcmSamples.length < fftSize) {
      return const SpectralAnalysisResult(
        spectralCutoffHz: 22050,
        isAuthenticLossless: true,
        isTranscode: false,
        maxObservedFrequencyHz: 22050.0,
        energyScore: 1.0,
        confidenceScore: 0.5,
      );
    }

    // Apply Hann Window to reduce spectral leakage
    final List<Complex> complexInput = List.filled(fftSize, const Complex(0, 0));
    for (int i = 0; i < fftSize; i++) {
      final double window = 0.5 * (1 - math.cos(2 * math.pi * i / (fftSize - 1)));
      complexInput[i] = Complex(pcmSamples[i] * window, 0.0);
    }

    // Run Cooley-Tukey FFT
    final List<Complex> spectrum = fft(complexInput);
    final int halfSize = fftSize ~/ 2;

    // Calculate magnitude spectrum
    final List<double> magnitudes = List.filled(halfSize, 0.0);
    double totalEnergy = 0.0;

    for (int i = 0; i < halfSize; i++) {
      final mag = spectrum[i].magnitude;
      magnitudes[i] = mag;
      totalEnergy += mag * mag;
    }

    // Bin frequency resolution
    final double binWidth = sampleRate / fftSize;

    // Detect brickwall cutoff frequency by analyzing energy above 15 kHz
    int cutoffBin = halfSize - 1;
    final int bin10k = (10000 / binWidth).floor().clamp(0, halfSize - 1);
    final int bin15k = (15000 / binWidth).floor().clamp(0, halfSize - 1);

    // Calculate baseline energy between 10 kHz and 15 kHz
    double baselineEnergy = 0.0;
    int baselineCount = 0;
    for (int i = bin10k; i < bin15k; i++) {
      baselineEnergy += magnitudes[i];
      baselineCount++;
    }
    final double avgBaseline = baselineCount > 0 ? baselineEnergy / baselineCount : 1.0;

    // Scan for sharp drop-off threshold (< 2% of baseline energy)
    for (int i = bin15k; i < halfSize; i++) {
      if (avgBaseline > 0.001 && (magnitudes[i] / avgBaseline) < 0.02) {
        cutoffBin = i;
        break;
      }
    }

    final int cutoffHz = (cutoffBin * binWidth).round();
    final bool isTranscode = cutoffHz < 20000;
    final bool isAuthentic = cutoffHz >= 21000;
    final double confidence = avgBaseline > 0.001 ? 0.95 : 0.60;

    return SpectralAnalysisResult(
      spectralCutoffHz: cutoffHz,
      isAuthenticLossless: isAuthentic,
      isTranscode: isTranscode,
      maxObservedFrequencyHz: cutoffHz.toDouble(),
      energyScore: totalEnergy,
      confidenceScore: confidence,
    );
  }
}
