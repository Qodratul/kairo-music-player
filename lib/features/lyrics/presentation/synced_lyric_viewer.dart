import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/theme/typography.dart';
import '../../player/presentation/providers/player_provider.dart';
import 'providers/lyrics_provider.dart';

/// Synchronized Lyric Viewer component that auto-scrolls and highlights active lyrics in real time.
class SyncedLyricViewer extends ConsumerStatefulWidget {
  const SyncedLyricViewer({super.key});

  @override
  ConsumerState<SyncedLyricViewer> createState() => _SyncedLyricViewerState();
}

class _SyncedLyricViewerState extends ConsumerState<SyncedLyricViewer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveIndex(int index, int totalLines) {
    if (!_scrollController.hasClients || index < 0 || totalLines == 0) return;

    const double itemHeight = 56.0;
    final double targetOffset = (index * itemHeight) - 100.0;
    final double maxOffset = _scrollController.position.maxScrollExtent;
    final double clampedOffset = targetOffset.clamp(0.0, maxOffset);

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(lyricsProvider);
    final activeIndex = ref.watch(activeLyricIndexProvider);

    ref.listen<int>(activeLyricIndexProvider, (prev, next) {
      final total = lyricsAsync.value?.length ?? 0;
      if (next != prev) {
        _scrollToActiveIndex(next, total);
      }
    });

    return lyricsAsync.when(
      data: (lyrics) {
        if (lyrics.isEmpty) {
          return const Center(
            child: Text(
              'No synchronized lyrics (.lrc) found.',
              style: KairoTypography.bodySmall,
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
          itemCount: lyrics.length,
          itemExtent: 56.0,
          itemBuilder: (context, index) {
            final line = lyrics[index];
            final isActive = index == activeIndex;

            return InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: () {
                ref.read(playerNotifierProvider.notifier).seek(line.timestamp);
              },
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: isActive
                      ? KairoTypography.titleMedium.copyWith(
                          color: KairoColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )
                      : KairoTypography.bodyMedium.copyWith(
                          color: KairoColors.textMuted,
                          fontSize: 14,
                        ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  child: Text(line.text.isNotEmpty ? line.text : '♪'),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Error loading lyrics: $err', style: KairoTypography.bodySmall),
      ),
    );
  }
}
