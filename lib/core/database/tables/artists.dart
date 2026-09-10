import 'package:drift/drift.dart';

@TableIndex(name: 'idx_artists_name', columns: {#name})
class Artists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get sortName => text().nullable()();
}
