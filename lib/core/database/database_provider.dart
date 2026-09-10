import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'daos/songs_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final songsDaoProvider = Provider<SongsDao>((ref) {
  return ref.watch(databaseProvider).songsDao;
});
