import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: KairoColors.surfaceElevated,
                child: album.coverArtPath != null && File(album.coverArtPath!).existsSync()
                    ? Image.file(
                        File(album.coverArtPath!),
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.album,
                          size: 48,
                          color: KairoColors.textSecondary,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KairoTypography.titleMedium.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    album.year != null ? '${album.year}' : 'Album',
                    style: KairoTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
