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

  Stream<List<Album>> watchAllAlbums() {
    return select(albums).watch();
  }

  Stream<List<Artist>> watchAllArtists() {
    return select(artists).watch();
  }

  Future<List<Song>> getAllSongs() {
    return select(songs).get();
  }

  Future<List<Song>> searchSongsFts(String query) {
    if (query.trim().isEmpty) return getAllSongs();
    final formattedQuery = '${query.trim().replaceAll("'", "''")}*';
    return db.searchSongsFts(formattedQuery).get();
  }

  Future<Artist?> getArtistById(int? id) {
    if (id == null) return Future.value(null);
    return (select(artists)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  Future<Album?> getAlbumById(int? id) {
    if (id == null) return Future.value(null);
    return (select(albums)..where((a) => a.id.equals(id))).getSingleOrNull();
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
