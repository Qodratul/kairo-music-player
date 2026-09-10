import 'dart:math' as math;

/// Types of Biquad IIR filters supported by the Audio DSP pipeline.
enum BiquadFilterType {
  flat,
  lowShelf,
  highShelf,
  peaking,
}

/// Biquad transfer function coefficients normalized by a0.
class BiquadCoefficients {
  final double b0;
  final double b1;
  final double b2;
  final double a1;
  final double a2;

  const BiquadCoefficients({
    required this.b0,
    required this.b1,
    required this.b2,
    required this.a1,
    required this.a2,
  });

  static const BiquadCoefficients identity = BiquadCoefficients(
    b0: 1.0,
    b1: 0.0,
    b2: 0.0,
    a1: 0.0,
    a2: 0.0,
  );
}

/// Second-order IIR Biquad Filter based on Robert Bristow-Johnson Audio EQ Cookbook.
class BiquadFilter {
  final BiquadFilterType type;
  final double frequency;
  final double gainDb;
  final double q;
  final double sampleRate;

  late final BiquadCoefficients coefficients;

  // Direct Form I delay memory
  double _x1 = 0.0;
  double _x2 = 0.0;
  double _y1 = 0.0;
  double _y2 = 0.0;

  BiquadFilter({
    required this.type,
    required this.frequency,
    required this.gainDb,
    this.q = 0.7071,
    this.sampleRate = 44100.0,
  }) {
    coefficients = _calculateCoefficients();
  }

  BiquadCoefficients _calculateCoefficients() {
    if (type == BiquadFilterType.flat || gainDb.abs() < 0.001) {
      return BiquadCoefficients.identity;
    }

    final A = math.pow(10, gainDb / 40).toDouble();
    final w0 = 2 * math.pi * frequency / sampleRate;
    final cosW0 = math.cos(w0);
    final sinW0 = math.sin(w0);
    final alpha = sinW0 / (2 * q);

    double b0 = 1.0, b1 = 0.0, b2 = 0.0, a0 = 1.0, a1 = 0.0, a2 = 0.0;

    switch (type) {
      case BiquadFilterType.lowShelf:
        final twoSqrtAAlpha = 2 * math.sqrt(A) * alpha;
        b0 = A * ((A + 1) - (A - 1) * cosW0 + twoSqrtAAlpha);
        b1 = 2 * A * ((A - 1) - (A + 1) * cosW0);
        b2 = A * ((A + 1) - (A - 1) * cosW0 - twoSqrtAAlpha);
        a0 = (A + 1) + (A - 1) * cosW0 + twoSqrtAAlpha;
        a1 = -2 * ((A - 1) + (A + 1) * cosW0);
        a2 = (A + 1) + (A - 1) * cosW0 - twoSqrtAAlpha;
        break;

      case BiquadFilterType.highShelf:
        final twoSqrtAAlpha = 2 * math.sqrt(A) * alpha;
        b0 = A * ((A + 1) + (A - 1) * cosW0 + twoSqrtAAlpha);
        b1 = -2 * A * ((A - 1) + (A + 1) * cosW0);
        b2 = A * ((A + 1) + (A - 1) * cosW0 - twoSqrtAAlpha);
        a0 = (A + 1) - (A - 1) * cosW0 + twoSqrtAAlpha;
        a1 = 2 * ((A - 1) - (A + 1) * cosW0);
        a2 = (A + 1) - (A - 1) * cosW0 - twoSqrtAAlpha;
        break;

      case BiquadFilterType.peaking:
        b0 = 1 + alpha * A;
        b1 = -2 * cosW0;
        b2 = 1 - alpha * A;
        a0 = 1 + alpha / A;
        a1 = -2 * cosW0;
        a2 = 1 - alpha / A;
        break;

      case BiquadFilterType.flat:
        return BiquadCoefficients.identity;
    }

    return BiquadCoefficients(
      b0: b0 / a0,
      b1: b1 / a0,
      b2: b2 / a0,
      a1: a1 / a0,
      a2: a2 / a0,
    );
  }

  /// Process a single PCM sample x[n] to y[n].
  double processSample(double input) {
    if (type == BiquadFilterType.flat || gainDb.abs() < 0.001) {
      return input;
    }

    final output = coefficients.b0 * input +
        coefficients.b1 * _x1 +
        coefficients.b2 * _x2 -
        coefficients.a1 * _y1 -
        coefficients.a2 * _y2;

    _x2 = _x1;
    _x1 = input;
    _y2 = _y1;
    _y1 = output;

    return output;
  }

  void reset() {
    _x1 = 0.0;
    _x2 = 0.0;
    _y1 = 0.0;
    _y2 = 0.0;
  }
}
