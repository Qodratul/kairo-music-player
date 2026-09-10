import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/presentation/providers/player_provider.dart';
import 'providers/library_provider.dart';

class DevScreen extends ConsumerStatefulWidget {
  const DevScreen({super.key});

  @override
  ConsumerState<DevScreen> createState() => _DevScreenState();
}

class _DevScreenState extends ConsumerState<DevScreen> {
  final TextEditingController _pathController = TextEditingController(
    text: '/storage/emulated/0/Music',
  );

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final songsAsync = ref.watch(songsWithDetailsStreamProvider);
    final currentItemAsync = ref.watch(currentMediaItemProvider);
    final playbackStateAsync = ref.watch(playbackStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KairoMP Dev UI (Wireframe)'),
        actions: [
          if (libraryState.isScanning)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Scan Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      labelText: 'Scan Folder Path',
                      hintText: '/storage/emulated/0/Music',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: libraryState.isScanning
                      ? null
                      : () {
                          final path = _pathController.text.trim();
                          if (path.isNotEmpty) {
                            ref
                                .read(libraryNotifierProvider.notifier)
                                .scanDirectory(path);
                          }
                        },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Scan'),
                ),
              ],
            ),
          ),

          if (libraryState.errorMessage != null)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8.0),
              width: double.infinity,
              child: Text(
                'Error: ${libraryState.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Songs List Section
          Expanded(
            child: songsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No songs found in database. Please scan a folder.'),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final currentItem = currentItemAsync.value;
                    final isPlayingThis = currentItem?.id == item.song.filePath;

                    return ListTile(
                      leading: Icon(
                        isPlayingThis ? Icons.graphic_eq : Icons.music_note,
                        color: isPlayingThis ? Theme.of(context).primaryColor : null,
                      ),
                      title: Text(
                        item.song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isPlayingThis ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${item.song.format.toUpperCase()} • ${_formatDuration(item.song.durationMs)}',
                      ),
                      onTap: () {
                        ref
                            .read(playerNotifierProvider.notifier)
                            .playAllWithDetails(items, initialIndex: index);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading songs: $err')),
            ),
          ),

          // Mini Player Section
          _buildMiniPlayer(
            context,
            currentItemAsync.value,
            playbackStateAsync.value,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(
    BuildContext context,
    MediaItem? currentItem,
    PlaybackState? playbackState,
  ) {
    if (currentItem == null) {
      return const SizedBox.shrink();
    }

    final isPlaying = playbackState?.playing ?? false;
    final position = playbackState?.position ?? Duration.zero;
    final duration = currentItem.duration ?? Duration.zero;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentItem.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      currentItem.artist ?? 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: () {
                  ref.read(playerNotifierProvider.notifier).skipToPrevious();
                },
              ),
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  ref.read(playerNotifierProvider.notifier).togglePlayPause();
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () {
                  ref.read(playerNotifierProvider.notifier).skipToNext();
                },
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              trackHeight: 2,
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
        ],
      ),
    );
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
