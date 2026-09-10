import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/audio_handler.dart';
import '../../../../core/audio/audio_handler_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../library/domain/models/song_with_details.dart';
import '../../../library/presentation/providers/library_provider.dart';

final currentMediaItemProvider = StreamProvider<MediaItem?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.mediaItem;
});

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState;
});

final currentlyPlayingSongProvider = Provider<Song?>((ref) {
  final mediaItem = ref.watch(currentMediaItemProvider).value;
  final songsAsync = ref.watch(songsWithDetailsStreamProvider);

  if (mediaItem == null) return null;
  final songs = songsAsync.value ?? [];
  try {
    return songs.firstWhere((s) => s.song.filePath == mediaItem.id).song;
  } catch (_) {
    return null;
  }
});

class HudVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final hudVisibleProvider =
    NotifierProvider<HudVisibilityNotifier, bool>(HudVisibilityNotifier.new);

class PlayerNotifier extends Notifier<void> {
  late final KairoMPAudioHandler _handler;

  @override
  void build() {
    _handler = ref.watch(audioHandlerProvider);
  }

  Future<void> playSongWithDetails(SongWithDetails item) async {
    final mediaItem = MediaItem(
      id: item.song.filePath,
      title: item.song.title,
      artist: item.artistName,
      album: item.albumTitle,
      duration: Duration(milliseconds: item.song.durationMs),
      artUri: item.coverArtPath != null ? Uri.file(item.coverArtPath!) : null,
      extras: {
        'format': item.song.format,
        'sampleRate': item.song.sampleRate,
        'bitDepth': item.song.bitDepth,
        'bitrate': item.song.bitrate,
        'coverArtPath': item.coverArtPath,
      },
    );

    await _handler.updateQueue([mediaItem]);
    await _handler.play();
  }

  Future<void> playAllWithDetails(List<SongWithDetails> items, {int initialIndex = 0}) async {
    if (items.isEmpty) return;

    final mediaItems = items
        .map(
          (item) => MediaItem(
            id: item.song.filePath,
            title: item.song.title,
            artist: item.artistName,
            album: item.albumTitle,
            duration: Duration(milliseconds: item.song.durationMs),
            artUri: item.coverArtPath != null ? Uri.file(item.coverArtPath!) : null,
            extras: {
              'format': item.song.format,
              'sampleRate': item.song.sampleRate,
              'bitDepth': item.song.bitDepth,
              'bitrate': item.song.bitrate,
              'coverArtPath': item.coverArtPath,
            },
          ),
        )
        .toList();

    await _handler.updateQueue(mediaItems);
    await _handler.skipToQueueItem(initialIndex);
    await _handler.play();
  }

  Future<void> playSong(Song song) async {
    final mediaItem = MediaItem(
      id: song.filePath,
      title: song.title,
      duration: Duration(milliseconds: song.durationMs),
      extras: {
        'format': song.format,
        'sampleRate': song.sampleRate,
        'bitDepth': song.bitDepth,
        'bitrate': song.bitrate,
      },
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
            extras: {
              'format': s.format,
              'sampleRate': s.sampleRate,
              'bitDepth': s.bitDepth,
              'bitrate': s.bitrate,
            },
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

  Future<void> toggleShuffle() async {
    final state = _handler.playbackState.value;
    final isShuffle = state.shuffleMode == AudioServiceShuffleMode.all;
    await _handler.setShuffleMode(
      isShuffle ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all,
    );
  }

  Future<void> cycleRepeatMode() async {
    final state = _handler.playbackState.value;
    final current = state.repeatMode;
    final next = switch (current) {
      AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
      AudioServiceRepeatMode.one => AudioServiceRepeatMode.none,
      _ => AudioServiceRepeatMode.none,
    };
    await _handler.setRepeatMode(next);
  }
}

final playerNotifierProvider = NotifierProvider<PlayerNotifier, void>(PlayerNotifier.new);
