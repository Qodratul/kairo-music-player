import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../player/presentation/providers/player_provider.dart';
import '../../data/lrc_parser.dart';
import '../../data/models/lyric_line.dart';

/// Provider fetching synchronized lyrics for the currently playing song.
final lyricsProvider = FutureProvider<List<LyricLine>>((ref) async {
  final currentItemAsync = ref.watch(currentMediaItemProvider);
  final currentItem = currentItemAsync.value;

  if (currentItem == null) return [];

  return LrcParser.parseForSongFile(currentItem.id);
});

/// Provider computing the index of the currently active lyric line based on playback position.
final activeLyricIndexProvider = Provider<int>((ref) {
  final lyricsAsync = ref.watch(lyricsProvider);
  final playbackStateAsync = ref.watch(playbackStateProvider);

  final lyrics = lyricsAsync.value ?? [];
  final position = playbackStateAsync.value?.position ?? Duration.zero;

  if (lyrics.isEmpty) return -1;

  int activeIndex = -1;
  for (int i = 0; i < lyrics.length; i++) {
    if (position >= lyrics[i].timestamp) {
      activeIndex = i;
    } else {
      break;
    }
  }

  return activeIndex;
});
