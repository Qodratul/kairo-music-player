import 'package:flutter_riverpod/flutter_riverpod.dart';

base class AppObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    // Logging state transitions for debugging
  }
}
