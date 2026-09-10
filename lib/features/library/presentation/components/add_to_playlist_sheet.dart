import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/models/song_with_details.dart';
import '../providers/library_provider.dart';

class AddToPlaylistSheet extends ConsumerStatefulWidget {
  final SongWithDetails item;

  const AddToPlaylistSheet({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<AddToPlaylistSheet> {
  final TextEditingController _newPlaylistController = TextEditingController();

  @override
  void dispose() {
    _newPlaylistController.dispose();
    super.dispose();
  }

  void _showNewPlaylistDialog() {
    _newPlaylistController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: KairoColors.surface,
          title: const Text('Buat Playlist Baru'),
          content: TextField(
            controller: _newPlaylistController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nama Playlist',
              hintText: 'Favorit Saya',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _newPlaylistController.text.trim();
                if (name.isNotEmpty) {
                  final songsDao = ref.read(songsDaoProvider);
                  final playlistId = await songsDao.createPlaylist(name);
                  await songsDao.addSongToPlaylist(playlistId, widget.item.song.id);

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lagu berhasil ditambahkan ke "$name"'),
                        backgroundColor: KairoColors.surfaceElevated,
                      ),
                    );
                  }
                }
              },
              child: const Text('Buat & Tambahkan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistsStreamProvider);

    return Material(
      color: KairoColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.playlist_add, color: KairoColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tambah ke Playlist',
                  style: KairoTypography.titleMedium.copyWith(color: KairoColors.primary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            widget.item.song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KairoTypography.bodySmall,
          ),
          const Divider(height: 24, color: KairoColors.surfaceBorder),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: KairoColors.surfaceElevated,
              child: Icon(Icons.add, color: KairoColors.primary),
            ),
            title: const Text('Buat Playlist Baru', style: KairoTypography.titleMedium),
            onTap: _showNewPlaylistDialog,
          ),
          const SizedBox(height: 8),
          playlistsAsync.when(
            data: (playlists) {
              if (playlists.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('Belum ada playlist. Buat playlist baru di atas.'),
                  ),
                );
              }
              return SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: const Icon(Icons.queue_music, color: KairoColors.textSecondary),
                      title: Text(playlist.name, style: KairoTypography.bodyMedium),
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final songsDao = ref.read(songsDaoProvider);
                        await songsDao.addSongToPlaylist(playlist.id, widget.item.song.id);

                        if (mounted) {
                          navigator.pop();
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Lagu berhasil ditambahkan ke "${playlist.name}"'),
                              backgroundColor: KairoColors.surfaceElevated,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error: $err'),
          ),
        ],
      ),
    ),
  );
}
}
