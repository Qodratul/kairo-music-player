import '../../../../core/database/app_database.dart';

/// Domain model combining [Song], [Artist], and [Album] entities.
class SongWithDetails {
  final Song song;
  final Artist? artist;
  final Album? album;

  const SongWithDetails({
    required this.song,
    this.artist,
    this.album,
  });

  String get artistName => (artist?.name != null && artist!.name.trim().isNotEmpty)
      ? artist!.name.trim()
      : 'Unknown Artist';

  String get albumTitle => (album?.title != null && album!.title.trim().isNotEmpty)
      ? album!.title.trim()
      : 'Unknown Album';

  String? get coverArtPath => album?.coverArtPath;
}
