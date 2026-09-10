import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_observer.dart';
import 'core/audio/audio_handler.dart';
import 'core/audio/audio_handler_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioHandler = await initAudioService();

  runApp(
    ProviderScope(
      observers: [AppObserver()],
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const KairoMPApp(),
    ),
  );
}
