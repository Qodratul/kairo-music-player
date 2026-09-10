import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/audio_handler.dart';
import '../../../../core/audio/audio_handler_provider.dart';
import '../../../../core/database/app_database.dart';

final currentMediaItemProvider = StreamProvider<MediaItem?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.mediaItem;
});

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState;
});

class PlayerNotifier extends Notifier<void> {
  late final KairoMPAudioHandler _handler;

  @override
  void build() {
    _handler = ref.watch(audioHandlerProvider);
  }

  Future<void> playSong(Song song) async {
    final mediaItem = MediaItem(
      id: song.filePath,
      title: song.title,
      duration: Duration(milliseconds: song.durationMs),
    );

    await _handler.updateQueue([mediaItem]);
    await _handler.play();
  }

  Future<void> playAll(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;

    final mediaItems = songs
        .map(
          (s) => MediaItem(
            id: s.filePath,
            title: s.title,
            duration: Duration(milliseconds: s.durationMs),
          ),
        )
        .toList();

    await _handler.updateQueue(mediaItems);
    await _handler.skipToQueueItem(initialIndex);
    await _handler.play();
  }

  Future<void> togglePlayPause() async {
    final state = _handler.playbackState.value;
    if (state.playing) {
      await _handler.pause();
    } else {
      await _handler.play();
    }
  }

  Future<void> skipToNext() => _handler.skipToNext();
  Future<void> skipToPrevious() => _handler.skipToPrevious();
  Future<void> seek(Duration position) => _handler.seek(position);
}

final playerNotifierProvider = NotifierProvider<PlayerNotifier, void>(PlayerNotifier.new);
