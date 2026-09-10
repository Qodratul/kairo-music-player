import 'package:drift/drift.dart';
import 'artists.dart';
import 'albums.dart';

@TableIndex(name: 'idx_songs_file_path', columns: {#filePath})
@TableIndex(name: 'idx_songs_artist_id', columns: {#artistId})
@TableIndex(name: 'idx_songs_album_id', columns: {#albumId})
@TableIndex(name: 'idx_songs_play_count', columns: {#playCount})
class Songs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get artistId => integer().nullable().references(Artists, #id)();
  IntColumn get albumId => integer().nullable().references(Albums, #id)();
  TextColumn get filePath => text().customConstraint('UNIQUE NOT NULL')();
  TextColumn get title => text()();
  IntColumn get durationMs => integer()();
  IntColumn get trackNumber => integer().nullable()();
  TextColumn get format => text()();
  IntColumn get sampleRate => integer().nullable()();
  IntColumn get bitDepth => integer().nullable()();
  IntColumn get bitrate => integer().nullable()();
  RealColumn get replaygainTrackGain => real().nullable()();
  BoolColumn get isLosslessVerified => boolean().withDefault(const Constant(false))();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
}
