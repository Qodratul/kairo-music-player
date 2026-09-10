import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/theme/typography.dart';
import '../../player/presentation/components/player_seekbar.dart';
import '../../player/presentation/now_playing_screen.dart';
import '../../player/presentation/providers/player_provider.dart';
import 'components/album_card.dart';
import 'components/artist_tile.dart';
import 'components/song_tile.dart';
import 'providers/library_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _scanPathController = TextEditingController(
    text: '/storage/emulated/0/Music',
  );

  @override
  void dispose() {
    _scanPathController.dispose();
    super.dispose();
  }

  void _showScanDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: KairoColors.surface,
          title: const Text('Scan Local Directory'),
          content: TextField(
            controller: _scanPathController,
            decoration: const InputDecoration(
              labelText: 'Directory Path',
              hintText: '/storage/emulated/0/Music',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final path = _scanPathController.text.trim();
                if (path.isNotEmpty) {
                  ref.read(libraryNotifierProvider.notifier).scanDirectory(path);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Scan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final currentItemAsync = ref.watch(currentMediaItemProvider);
    final playbackStateAsync = ref.watch(playbackStateProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KairoMP Library'),
          actions: [
            if (libraryState.isScanning)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: _showScanDialog,
                tooltip: 'Scan Directory',
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(104),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: TextField(
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).setQuery(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search songs, albums, artists...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: KairoColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // Tab Bar
                const TabBar(
                  isScrollable: false,
                  indicatorColor: KairoColors.primary,
                  labelColor: KairoColors.primary,
                  unselectedLabelColor: KairoColors.textSecondary,
                  tabs: [
                    Tab(text: 'Songs'),
                    Tab(text: 'Albums'),
                    Tab(text: 'Artists'),
                    Tab(text: 'Playlists'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildSongsTab(currentItemAsync.value),
                  _buildAlbumsTab(),
                  _buildArtistsTab(),
                  _buildPlaylistsTab(),
                ],
              ),
            ),
            // Persistent Mini Player
            _buildMiniPlayer(
              context,
              currentItemAsync.value,
              playbackStateAsync.value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsTab(MediaItem? currentItem) {
    final songsAsync = ref.watch(filteredSongsProvider);

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: Text(
              'No songs found.',
              style: KairoTypography.bodySmall,
            ),
          );
        }
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final isPlayingThis = currentItem?.id == song.filePath;

            return SongTile(
              song: song,
              isPlaying: isPlayingThis,
              onTap: () {
                ref
                    .read(playerNotifierProvider.notifier)
                    .playAll(songs, initialIndex: index);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildAlbumsTab() {
    final albumsAsync = ref.watch(filteredAlbumsProvider);

    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) {
          return const Center(
            child: Text(
              'No albums found.',
              style: KairoTypography.bodySmall,
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.82,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return AlbumCard(
              album: album,
              onTap: () {
                // Album details
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildArtistsTab() {
    final artistsAsync = ref.watch(filteredArtistsProvider);

    return artistsAsync.when(
      data: (artists) {
        if (artists.isEmpty) {
          return const Center(
            child: Text(
              'No artists found.',
              style: KairoTypography.bodySmall,
            ),
          );
        }
        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return ArtistTile(
              artist: artist,
              onTap: () {
                // Artist details
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildPlaylistsTab() {
    return const Center(
      child: Text(
        'Playlists feature coming soon.',
        style: KairoTypography.bodySmall,
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
    final duration = currentItem.duration ?? Duration.zero;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const NowPlayingScreen(),
          ),
        );
      },
      child: Container(
        color: KairoColors.surfaceElevated,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.music_note, color: KairoColors.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentItem.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KairoTypography.titleMedium.copyWith(fontSize: 14),
                      ),
                      Text(
                        currentItem.artist ?? 'Unknown Artist',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KairoTypography.bodySmall,
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
                  color: KairoColors.primary,
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
            PlayerSeekbar(duration: duration, compact: true),
          ],
        ),
      ),
    );
  }
}
