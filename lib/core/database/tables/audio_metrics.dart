import 'package:drift/drift.dart';
import 'songs.dart';

class AudioMetrics extends Table {
  IntColumn get songId => integer().references(Songs, #id)();
  RealColumn get truePeakDb => real().nullable()();
  IntColumn get spectralCutoff => integer().nullable()();
  RealColumn get energyScore => real().nullable()();
  TextColumn get embeddingVector => text().nullable()();

  @override
  Set<Column> get primaryKey => {songId};
}
