import 'package:drift/drift.dart';
import 'artists.dart';

class Albums extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get artistId => integer().nullable().references(Artists, #id)();
  IntColumn get year => integer().nullable()();
  TextColumn get coverArtPath => text().nullable()();
}
