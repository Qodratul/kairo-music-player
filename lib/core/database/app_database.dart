import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'daos/songs_dao.dart';
import 'tables/albums.dart';
import 'tables/artists.dart';
import 'tables/audio_metrics.dart';
import 'tables/playlist_tracks.dart';
import 'tables/playlists.dart';
import 'tables/songs.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Artists,
    Albums,
    Songs,
    Playlists,
    PlaylistTracks,
    AudioMetrics,
  ],
  daos: [
    SongsDao,
  ],
  include: {
    'tables/songs_fts.drift',
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'kairomp.sqlite'));

    if (Platform.isAndroid) {
      // Workaround applied dynamically via SQLite libs on modern drift.
    }

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
