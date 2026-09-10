import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

Future<KairoMPAudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => KairoMPAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.kairomp.channel.audio',
      androidNotificationChannelName: 'KairoMP Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidShowNotificationBadge: true,
    ),
  );
}

class KairoMPAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  // Using ConcatenatingAudioSource to manage a playlist directly
  // ignore: deprecated_member_use
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  KairoMPAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    await _player.setAudioSource(_playlist);

    // Broadcast playback state changes to audio_service
    _player.playbackEventStream.listen(_broadcastState);

    // Sync just_audio's current item & queue with audio_service
    _player.sequenceStateStream.listen((SequenceState? sequenceState) {
      if (sequenceState == null) return;
      final sequence = sequenceState.effectiveSequence;
      if (sequence.isEmpty) {
        mediaItem.add(null);
        return;
      }
      final items = sequence.map((s) => s.tag as MediaItem).toList();
      queue.add(items);
      
      final int currentIndex = sequenceState.currentIndex ?? 0;
      if (currentIndex < items.length) {
        mediaItem.add(items[currentIndex]);
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    await _playlist.clear();
    await _playlist.addAll(queue.map(_createAudioSource).toList());
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    await _playlist.add(_createAudioSource(mediaItem));
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    await _playlist.addAll(mediaItems.map(_createAudioSource).toList());
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await _playlist.removeAt(index);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  UriAudioSource _createAudioSource(MediaItem item) {
    final uri = item.id.startsWith('http') || item.id.startsWith('file://')
        ? Uri.parse(item.id)
        : Uri.file(item.id);
    return AudioSource.uri(uri, tag: item);
  }
}
