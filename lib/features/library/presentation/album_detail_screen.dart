import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/theme/typography.dart';
import '../../player/presentation/providers/player_provider.dart';
import '../domain/models/song_with_details.dart';
import 'components/song_tile.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  final Album album;

  const AlbumDetailScreen({
    super.key,
    required this.album,
  });

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  List<SongWithDetails> _albumSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbumSongs();
  }

  void _loadAlbumSongs() async {
    final songsDao = ref.read(songsDaoProvider);
    final songs = await songsDao.getSongsForAlbum(widget.album.id);
    if (mounted) {
      setState(() {
        _albumSongs = songs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = ref.watch(currentMediaItemProvider).value;

    return Scaffold(
      backgroundColor: KairoColors.background,
      appBar: AppBar(
        title: Text(widget.album.title),
        backgroundColor: KairoColors.background,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: KairoColors.surface,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          width: 90,
                          height: 90,
                          color: KairoColors.surfaceElevated,
                          child: widget.album.coverArtPath != null &&
                                  File(widget.album.coverArtPath!).existsSync()
                              ? Image.file(
                                  File(widget.album.coverArtPath!),
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.album,
                                  size: 48,
                                  color: KairoColors.textSecondary,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.album.title,
                              style: KairoTypography.titleLarge,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.album.year != null ? '${widget.album.year}' : 'Album',
                              style: KairoTypography.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_albumSongs.length} Tracks',
                              style: KairoTypography.telemetryLabel,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: KairoColors.surfaceBorder),

                // Songs List
                Expanded(
                  child: _albumSongs.isEmpty
                      ? const Center(
                          child: Text(
                            'No songs in this album.',
                            style: KairoTypography.bodySmall,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _albumSongs.length,
                          itemBuilder: (context, index) {
                            final item = _albumSongs[index];
                            final isPlayingThis = currentItem?.id == item.song.filePath;

                            return SongTile(
                              item: item,
                              isPlaying: isPlayingThis,
                              onTap: () {
                                ref
                                    .read(playerNotifierProvider.notifier)
                                    .playAllWithDetails(_albumSongs, initialIndex: index);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
