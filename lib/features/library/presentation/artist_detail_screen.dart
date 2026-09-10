import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/theme/typography.dart';
import '../../player/presentation/providers/player_provider.dart';
import '../domain/models/song_with_details.dart';
import 'components/song_tile.dart';

class ArtistDetailScreen extends ConsumerStatefulWidget {
  final Artist artist;

  const ArtistDetailScreen({
    super.key,
    required this.artist,
  });

  @override
  ConsumerState<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends ConsumerState<ArtistDetailScreen> {
  List<SongWithDetails> _artistSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtistSongs();
  }

  void _loadArtistSongs() async {
    final songsDao = ref.read(songsDaoProvider);
    final songs = await songsDao.getSongsForArtist(widget.artist.id);
    if (mounted) {
      setState(() {
        _artistSongs = songs;
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
        title: Text(widget.artist.name),
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
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: KairoColors.surfaceElevated,
                        child: Text(
                          widget.artist.name.isNotEmpty
                              ? widget.artist.name[0].toUpperCase()
                              : 'A',
                          style: KairoTypography.titleLarge
                              .copyWith(color: KairoColors.primary, fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.artist.name,
                              style: KairoTypography.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_artistSongs.length} Songs',
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
                  child: _artistSongs.isEmpty
                      ? const Center(
                          child: Text(
                            'No songs by this artist.',
                            style: KairoTypography.bodySmall,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _artistSongs.length,
                          itemBuilder: (context, index) {
                            final item = _artistSongs[index];
                            final isPlayingThis = currentItem?.id == item.song.filePath;

                            return SongTile(
                              item: item,
                              isPlaying: isPlayingThis,
                              onTap: () {
                                ref
                                    .read(playerNotifierProvider.notifier)
                                    .playAllWithDetails(_artistSongs, initialIndex: index);
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
