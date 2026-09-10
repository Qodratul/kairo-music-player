import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/theme/typography.dart';
import '../../player/presentation/providers/player_provider.dart';
import '../domain/models/song_with_details.dart';
import 'components/song_tile.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
  });

  void _confirmDeletePlaylist(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: KairoColors.surface,
          title: const Text('Hapus Playlist'),
          content: Text('Apakah Anda yakin ingin menghapus playlist "${playlist.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: KairoColors.accentRed),
              onPressed: () async {
                final songsDao = ref.read(songsDaoProvider);
                await songsDao.deletePlaylist(playlist.id);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsDao = ref.watch(songsDaoProvider);
    final playlistSongsStream = songsDao.watchSongsForPlaylist(playlist.id);
    final currentItem = ref.watch(currentMediaItemProvider).value;

    return Scaffold(
      backgroundColor: KairoColors.background,
      appBar: AppBar(
        title: Text(playlist.name),
        backgroundColor: KairoColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: KairoColors.accentRed),
            onPressed: () => _confirmDeletePlaylist(context, ref),
            tooltip: 'Hapus Playlist',
          ),
        ],
      ),
      body: StreamBuilder<List<SongWithDetails>>(
        stream: playlistSongsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];
          final totalMs = items.fold<int>(0, (sum, item) => sum + item.song.durationMs);

          return Column(
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                color: KairoColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: KairoColors.surfaceElevated,
                          child: Icon(Icons.queue_music, color: KairoColors.primary, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playlist.name,
                                style: KairoTypography.titleLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${items.length} Lagu • Total Durasi: ${_formatTotalDuration(totalMs)}',
                                style: KairoTypography.telemetryLabel,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KairoColors.primary,
                              foregroundColor: KairoColors.background,
                            ),
                            onPressed: items.isEmpty
                                ? null
                                : () {
                                    ref
                                        .read(playerNotifierProvider.notifier)
                                        .playAllWithDetails(items, initialIndex: 0);
                                  },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play All'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: KairoColors.primary,
                              side: const BorderSide(color: KairoColors.primary),
                            ),
                            onPressed: items.isEmpty
                                ? null
                                : () async {
                                    final playerNotifier = ref.read(playerNotifierProvider.notifier);
                                    await playerNotifier.toggleShuffle();
                                    await playerNotifier.playAllWithDetails(items, initialIndex: 0);
                                  },
                            icon: const Icon(Icons.shuffle),
                            label: const Text('Shuffle All'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: KairoColors.surfaceBorder),

              // Playlist Tracks List
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'Playlist ini masih kosong.\nTambahkan lagu dari tab Songs, Album, atau Artist.',
                          textAlign: TextAlign.center,
                          style: KairoTypography.bodySmall,
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isPlayingThis = currentItem?.id == item.song.filePath;

                          return SongTile(
                            item: item,
                            isPlaying: isPlayingThis,
                            onTap: () {
                              ref
                                  .read(playerNotifierProvider.notifier)
                                  .playAllWithDetails(items, initialIndex: index);
                            },
                            onRemoveFromPlaylist: () async {
                              await songsDao.removeSongFromPlaylist(playlist.id, item.song.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('"${item.song.title}" dihapus dari playlist'),
                                    backgroundColor: KairoColors.surfaceElevated,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTotalDuration(int ms) {
    final d = Duration(milliseconds: ms);
    if (d.inHours > 0) {
      return '${d.inHours}j ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }
}
