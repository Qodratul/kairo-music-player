import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/models/smart_playlist_query.dart';

/// Repository for executing structured [SmartPlaylistQuery] against local Drift SQLite database.
class SmartPlaylistRepository {
  final AppDatabase _db;

  SmartPlaylistRepository(this._db);

  /// Executes a [SmartPlaylistQuery] and returns the resulting list of [Song]s.
  Future<List<Song>> executeSmartQuery(SmartPlaylistQuery query) async {
    final songQuery = _db.select(_db.songs);

    // Apply Year Filter via Albums table
    if (query.releaseYearRange != null && query.releaseYearRange!.length >= 2) {
      final startYear = query.releaseYearRange![0];
      final endYear = query.releaseYearRange![1];

      songQuery.where((s) => s.albumId.isInQuery(
            _db.select(_db.albums)
              ..where((a) =>
                  a.year.isBiggerOrEqualValue(startYear) &
                  a.year.isSmallerOrEqualValue(endYear))
              ..addColumns([_db.albums.id]),
          ));
    }

    // Apply Sorting Order
    switch (query.sortBy) {
      case 'last_played':
        songQuery.orderBy([(s) => OrderingTerm.desc(s.lastPlayedAt)]);
        break;
      case 'duration':
        songQuery.orderBy([(s) => OrderingTerm.desc(s.durationMs)]);
        break;
      case 'play_count':
      default:
        songQuery.orderBy([(s) => OrderingTerm.desc(s.playCount)]);
        break;
    }

    // Apply Query Limit
    songQuery.limit(query.limit);

    return songQuery.get();
  }
}
