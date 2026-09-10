import 'package:drift/drift.dart';
import 'playlists.dart';
import 'songs.dart';

@TableIndex(name: 'idx_playlist_tracks_playlist_id', columns: {#playlistId})
@TableIndex(name: 'idx_playlist_tracks_song_id', columns: {#songId})
class PlaylistTracks extends Table {
  IntColumn get playlistId => integer().references(Playlists, #id)();
  IntColumn get songId => integer().references(Songs, #id)();
  IntColumn get trackOrder => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [{playlistId, songId}];
}
