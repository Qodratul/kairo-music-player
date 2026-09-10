import 'package:flutter/material.dart';

import '../features/library/presentation/dev_screen.dart';

class KairoMPApp extends StatelessWidget {
  const KairoMPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KairoMP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D0D11),
          brightness: Brightness.dark,
        ),
      ),
      home: const DevScreen(),
    );
  }
}
