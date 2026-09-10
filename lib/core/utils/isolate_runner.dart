import 'dart:isolate';
import 'package:fpdart/fpdart.dart';

class IsolateRunner {
  /// Helper to run a heavy task in a background isolate and return `Either<String, R>`
  static Future<Either<String, R>> run<M, R>(
    Future<R> Function(M) computation,
    M message,
  ) async {
    try {
      final result = await Isolate.run(() => computation(message));
      return Right(result);
    } catch (e, st) {
      return Left('Isolate execution failed: $e\n$st');
    }
  }
}
