import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography.dart';

class ArtistTile extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const ArtistTile({
    super.key,
    required this.artist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      leading: CircleAvatar(
        backgroundColor: KairoColors.surfaceElevated,
        child: Text(
          artist.name.isNotEmpty ? artist.name[0].toUpperCase() : 'A',
          style: KairoTypography.titleMedium.copyWith(color: KairoColors.primary),
        ),
      ),
      title: Text(
        artist.name,
        style: KairoTypography.titleMedium.copyWith(fontSize: 15),
      ),
      trailing: const Icon(Icons.chevron_right, color: KairoColors.textSecondary),
      onTap: onTap,
    );
  }
}
