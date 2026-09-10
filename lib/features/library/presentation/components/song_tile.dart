import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final String? coverArtPath;
  final String? artistName;
  final VoidCallback onTap;

  const SongTile({
    super.key,
    required this.song,
    required this.isPlaying,
    this.coverArtPath,
    this.artistName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: 48,
          height: 48,
          color: KairoColors.surfaceElevated,
          child: coverArtPath != null && File(coverArtPath!).existsSync()
              ? Image.file(
                  File(coverArtPath!),
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
              artistName ?? 'Unknown Artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KairoTypography.bodySmall,
            ),
          ),
        ],
      ),
      trailing: Text(
        _formatDuration(song.durationMs),
        style: KairoTypography.timestamp,
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
