import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/library/presentation/library_screen.dart';

class KairoMPApp extends StatelessWidget {
  const KairoMPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KairoMP',
      debugShowCheckedModeBanner: false,
      theme: KairoTheme.darkTheme,
      home: const LibraryScreen(),
    );
  }
}
