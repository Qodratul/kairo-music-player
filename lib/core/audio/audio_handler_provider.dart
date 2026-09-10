import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_handler.dart';

final audioHandlerProvider = Provider<KairoMPAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in ProviderScope');
});
