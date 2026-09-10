import 'package:drift/drift.dart';

class Artists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get sortName => text().nullable()();
}
