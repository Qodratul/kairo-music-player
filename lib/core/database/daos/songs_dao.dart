import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/albums.dart';
import '../tables/artists.dart';
import '../tables/songs.dart';

part 'songs_dao.g.dart';

@DriftAccessor(tables: [Songs, Artists, Albums])
class SongsDao extends DatabaseAccessor<AppDatabase> with _$SongsDaoMixin {
  SongsDao(super.db);

  Stream<List<Song>> watchAllSongs() {
    return select(songs).watch();
  }

  Future<List<Song>> getAllSongs() {
    return select(songs).get();
  }

  Future<int> insertSong(SongsCompanion song) {
    return into(songs).insertOnConflictUpdate(song);
  }

  Future<void> insertOrUpdateSongsBatch(List<SongsCompanion> songCompanions) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(songs, songCompanions);
    });
  }

  Future<int?> getOrInsertArtist(String? name) async {
    if (name == null || name.trim().isEmpty) return null;
    final existing = await (select(artists)..where((a) => a.name.equals(name))).getSingleOrNull();
    if (existing != null) return existing.id;
    return into(artists).insert(ArtistsCompanion.insert(name: name));
  }

  Future<int?> getOrInsertAlbum(String? title, int? artistId, String? coverArtPath, int? year) async {
    if (title == null || title.trim().isEmpty) return null;
    final existing = await (select(albums)..where((a) => a.title.equals(title))).getSingleOrNull();
    if (existing != null) return existing.id;
    return into(albums).insert(
      AlbumsCompanion.insert(
        title: title,
        artistId: Value(artistId),
        coverArtPath: Value(coverArtPath),
        year: Value(year),
      ),
    );
  }
}
