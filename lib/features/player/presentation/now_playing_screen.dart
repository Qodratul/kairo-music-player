import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/theme/typography.dart';
import 'components/telemetry_hud.dart';
import 'providers/player_provider.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentItemAsync = ref.watch(currentMediaItemProvider);
    final playbackStateAsync = ref.watch(playbackStateProvider);
    final showHud = ref.watch(hudVisibleProvider);

    final currentItem = currentItemAsync.value;
    final playbackState = playbackStateAsync.value;

    if (currentItem == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('NOW PLAYING'),
        ),
        body: const Center(
          child: Text(
            'No track is currently playing.',
            style: KairoTypography.bodyMedium,
          ),
        ),
      );
    }

    final isPlaying = playbackState?.playing ?? false;
    final position = playbackState?.position ?? Duration.zero;
    final duration = currentItem.duration ?? Duration.zero;
    final isShuffle = playbackState?.shuffleMode == AudioServiceShuffleMode.all;
    final repeatMode = playbackState?.repeatMode ?? AudioServiceRepeatMode.none;

    final coverPath = currentItem.artUri?.toFilePath() ?? currentItem.extras?['coverArtPath'] as String?;

    return Scaffold(
      backgroundColor: KairoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Minimize',
        ),
        title: const Text(
          'NOW PLAYING',
          style: KairoTypography.telemetryTitle,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.developer_board,
              color: showHud ? KairoColors.primary : KairoColors.textMuted,
            ),
            onPressed: () {
              ref.read(hudVisibleProvider.notifier).toggle();
            },
            tooltip: 'Toggle Telemetry HUD',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            children: [
              if (!showHud) const Spacer(),

              // High-Res Album Cover Art Display (collapses height if HUD is enabled)
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: showHud ? 200 : 260,
                  height: showHud ? 200 : 260,
                  decoration: BoxDecoration(
                    color: KairoColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: KairoColors.surfaceBorder, width: 1.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: coverPath != null && File(coverPath).existsSync()
                      ? Image.file(
                          File(coverPath),
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: Icon(
                            Icons.music_note,
                            size: 80,
                            color: KairoColors.textSecondary,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Audio Hardware Telemetry HUD Panel
              if (showHud)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: TelemetryHUD(),
                ),

              if (!showHud) const Spacer(),

              // Metadata Info Section
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentItem.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KairoTypography.titleLarge.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${currentItem.artist ?? "Unknown Artist"}${currentItem.album != null ? " • ${currentItem.album}" : ""}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KairoTypography.bodyMedium.copyWith(
                        color: KairoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Interactive Seekbar Section
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      trackHeight: 3,
                      activeTrackColor: KairoColors.primary,
                      inactiveTrackColor: KairoColors.surfaceBorder,
                      thumbColor: KairoColors.primary,
                    ),
                    child: Slider(
                      value: position.inMilliseconds
                          .clamp(0, duration.inMilliseconds)
                          .toDouble(),
                      max: duration.inMilliseconds > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1.0,
                      onChanged: (val) {
                        ref
                            .read(playerNotifierProvider.notifier)
                            .seek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: KairoTypography.timestamp,
                        ),
                        Text(
                          _formatDuration(duration),
                          style: KairoTypography.timestamp,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Player Control Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shuffle Button
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: isShuffle ? KairoColors.primary : KairoColors.textMuted,
                      size: 24,
                    ),
                    onPressed: () {
                      ref.read(playerNotifierProvider.notifier).toggleShuffle();
                    },
                    tooltip: 'Shuffle',
                  ),

                  // Skip Previous Button
                  IconButton(
                    icon: const Icon(
                      Icons.skip_previous_rounded,
                      color: KairoColors.textPrimary,
                      size: 36,
                    ),
                    onPressed: () {
                      ref.read(playerNotifierProvider.notifier).skipToPrevious();
                    },
                    tooltip: 'Previous',
                  ),

                  // Play / Pause FAB
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: KairoColors.primary,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: KairoColors.background,
                        size: 36,
                      ),
                      onPressed: () {
                        ref.read(playerNotifierProvider.notifier).togglePlayPause();
                      },
                      tooltip: isPlaying ? 'Pause' : 'Play',
                    ),
                  ),

                  // Skip Next Button
                  IconButton(
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: KairoColors.textPrimary,
                      size: 36,
                    ),
                    onPressed: () {
                      ref.read(playerNotifierProvider.notifier).skipToNext();
                    },
                    tooltip: 'Next',
                  ),

                  // Repeat Mode Button
                  IconButton(
                    icon: Icon(
                      repeatMode == AudioServiceRepeatMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: repeatMode != AudioServiceRepeatMode.none
                          ? KairoColors.primary
                          : KairoColors.textMuted,
                      size: 24,
                    ),
                    onPressed: () {
                      ref.read(playerNotifierProvider.notifier).cycleRepeatMode();
                    },
                    tooltip: 'Repeat Mode',
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
