import 'package:drift/drift.dart';

import '../../../features/library/domain/models/song_with_details.dart';
import '../app_database.dart';
import '../tables/albums.dart';
import '../tables/artists.dart';
import '../tables/playlist_tracks.dart';
import '../tables/playlists.dart';
import '../tables/songs.dart';

part 'songs_dao.g.dart';

@DriftAccessor(tables: [Songs, Artists, Albums, Playlists, PlaylistTracks])
class SongsDao extends DatabaseAccessor<AppDatabase> with _$SongsDaoMixin {
  SongsDao(super.db);

  Stream<List<SongWithDetails>> watchAllSongsWithDetails() {
    final query = select(songs).join([
      leftOuterJoin(artists, artists.id.equalsExp(songs.artistId)),
      leftOuterJoin(albums, albums.id.equalsExp(songs.albumId)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return SongWithDetails(
          song: row.readTable(songs),
          artist: row.readTableOrNull(artists),
          album: row.readTableOrNull(albums),
        );
      }).toList();
    });
  }

  Stream<List<Album>> watchAllAlbums() {
    return select(albums).watch();
  }

  Stream<List<Artist>> watchAllArtists() {
    return select(artists).watch();
  }

  Stream<List<Playlist>> watchAllPlaylists() {
    return select(playlists).watch();
  }

  Stream<List<SongWithDetails>> watchSongsForPlaylist(int playlistId) {
    final query = select(playlistTracks).join([
      innerJoin(songs, songs.id.equalsExp(playlistTracks.songId)),
      leftOuterJoin(artists, artists.id.equalsExp(songs.artistId)),
      leftOuterJoin(albums, albums.id.equalsExp(songs.albumId)),
    ])
      ..where(playlistTracks.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(playlistTracks.trackOrder)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return SongWithDetails(
          song: row.readTable(songs),
          artist: row.readTableOrNull(artists),
          album: row.readTableOrNull(albums),
        );
      }).toList();
    });
  }

  Future<List<SongWithDetails>> getSongsForPlaylist(int playlistId) async {
    final query = select(playlistTracks).join([
      innerJoin(songs, songs.id.equalsExp(playlistTracks.songId)),
      leftOuterJoin(artists, artists.id.equalsExp(songs.artistId)),
      leftOuterJoin(albums, albums.id.equalsExp(songs.albumId)),
    ])
      ..where(playlistTracks.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(playlistTracks.trackOrder)]);

    final rows = await query.get();
    return rows.map((row) {
      return SongWithDetails(
        song: row.readTable(songs),
        artist: row.readTableOrNull(artists),
        album: row.readTableOrNull(albums),
      );
    }).toList();
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    final query = select(playlistTracks)..where((pt) => pt.playlistId.equals(playlistId));
    final existingTracks = await query.get();

    // Prevent duplicate insertion of same song into playlist
    if (existingTracks.any((t) => t.songId == songId)) {
      return;
    }

    final nextOrder = existingTracks.isEmpty
        ? 1
        : existingTracks.map((t) => t.trackOrder).reduce((a, b) => a > b ? a : b) + 1;

    await into(playlistTracks).insert(
      PlaylistTracksCompanion.insert(
        playlistId: playlistId,
        songId: songId,
        trackOrder: nextOrder,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    await (delete(playlistTracks)
          ..where((pt) => pt.playlistId.equals(playlistId) & pt.songId.equals(songId)))
        .go();
  }

  Future<void> deletePlaylist(int playlistId) async {
    await transaction(() async {
      await (delete(playlistTracks)..where((pt) => pt.playlistId.equals(playlistId))).go();
      await (delete(playlists)..where((p) => p.id.equals(playlistId))).go();
    });
  }

  Future<List<SongWithDetails>> getSongsForAlbum(int albumId) {
    final query = select(songs).join([
      leftOuterJoin(artists, artists.id.equalsExp(songs.artistId)),
      leftOuterJoin(albums, albums.id.equalsExp(songs.albumId)),
    ])..where(songs.albumId.equals(albumId));

    return query.get().then((rows) {
      return rows.map((row) {
        return SongWithDetails(
          song: row.readTable(songs),
          artist: row.readTableOrNull(artists),
          album: row.readTableOrNull(albums),
        );
      }).toList();
    });
  }

  Future<List<SongWithDetails>> getSongsForArtist(int artistId) {
    final query = select(songs).join([
      leftOuterJoin(artists, artists.id.equalsExp(songs.artistId)),
      leftOuterJoin(albums, albums.id.equalsExp(songs.albumId)),
    ])..where(songs.artistId.equals(artistId));

    return query.get().then((rows) {
      return rows.map((row) {
        return SongWithDetails(
          song: row.readTable(songs),
          artist: row.readTableOrNull(artists),
          album: row.readTableOrNull(albums),
        );
      }).toList();
    });
  }

  Future<int> createPlaylist(String name) {
    return into(playlists).insert(
      PlaylistsCompanion.insert(
        name: name,
        createdAt: Value(DateTime.now()),
      ),
    );
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
    final cleanName = name.trim();
    final existing = await (select(artists)..where((a) => a.name.equals(cleanName))).getSingleOrNull();
    if (existing != null) return existing.id;
    return into(artists).insert(ArtistsCompanion.insert(name: cleanName));
  }

  Future<int?> getOrInsertAlbum(String? title, int? artistId, String? coverArtPath, int? year) async {
    if (title == null || title.trim().isEmpty) return null;
    final cleanTitle = title.trim();
    final existing = await (select(albums)..where((a) => a.title.equals(cleanTitle))).getSingleOrNull();
    if (existing != null) return existing.id;
    return into(albums).insert(
      AlbumsCompanion.insert(
        title: cleanTitle,
        artistId: Value(artistId),
        coverArtPath: Value(coverArtPath),
        year: Value(year),
      ),
    );
  }
}
