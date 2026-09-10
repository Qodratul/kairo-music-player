import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/models/song_with_details.dart';
import 'add_to_playlist_sheet.dart';

class SongTile extends StatelessWidget {
  final SongWithDetails item;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onRemoveFromPlaylist;

  const SongTile({
    super.key,
    required this.item,
    required this.isPlaying,
    required this.onTap,
    this.onRemoveFromPlaylist,
  });

  void _showSongOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Material(
          color: KairoColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.playlist_add, color: KairoColors.primary),
                  title: const Text('Tambah ke Playlist'),
                  onTap: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddToPlaylistSheet(item: item),
                    );
                  },
                ),
                if (onRemoveFromPlaylist != null)
                  ListTile(
                    leading: const Icon(Icons.playlist_remove, color: KairoColors.accentRed),
                    title: const Text(
                      'Hapus dari Playlist ini',
                      style: TextStyle(color: KairoColors.accentRed),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      onRemoveFromPlaylist!();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = item.song;
    final coverPath = item.coverArtPath;
    final artistName = item.artistName;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: 48,
          height: 48,
          color: KairoColors.surfaceElevated,
          child: coverPath != null && File(coverPath).existsSync()
              ? Image.file(
                  File(coverPath),
                  fit: BoxFit.cover,
                )
              : Icon(
                  isPlaying ? Icons.graphic_eq : Icons.music_note,
                  color: isPlaying ? KairoColors.primary : KairoColors.textSecondary,
                  size: 24,
                ),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPlaying ? KairoColors.primary : KairoColors.textPrimary,
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
            decoration: BoxDecoration(
              color: KairoColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: KairoColors.surfaceBorder, width: 0.5),
            ),
            child: Text(
              song.format.toUpperCase(),
              style: KairoTypography.telemetryLabel.copyWith(
                fontSize: 10,
                color: song.format.toLowerCase() == 'flac' ? KairoColors.primary : KairoColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              artistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KairoTypography.bodySmall,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(song.durationMs),
            style: KairoTypography.timestamp,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20, color: KairoColors.textSecondary),
            onPressed: () => _showSongOptions(context),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
