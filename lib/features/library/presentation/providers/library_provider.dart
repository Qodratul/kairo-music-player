import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/scanner_repository.dart';

class LibraryState {
  final bool isScanning;
  final String? errorMessage;
  final int scannedCount;

  const LibraryState({
    this.isScanning = false,
    this.errorMessage,
    this.scannedCount = 0,
  });

  LibraryState copyWith({
    bool? isScanning,
    String? errorMessage,
    int? scannedCount,
  }) {
    return LibraryState(
      isScanning: isScanning ?? this.isScanning,
      errorMessage: errorMessage,
      scannedCount: scannedCount ?? this.scannedCount,
    );
  }
}

class LibraryNotifier extends Notifier<LibraryState> {
  final ScannerRepository _scannerRepository = ScannerRepository();

  @override
  LibraryState build() {
    return const LibraryState();
  }

  Future<void> scanDirectory(String directoryPath) async {
    state = state.copyWith(isScanning: true, errorMessage: null);

    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final result = await _scannerRepository.scanDirectories(
        [directoryPath],
        cacheDir.path,
      );

      await result.fold(
        (error) async {
          state = state.copyWith(isScanning: false, errorMessage: error);
        },
        (scannedSongs) async {
          final songsDao = ref.read(songsDaoProvider);

          final companions = <SongsCompanion>[];
          for (final dto in scannedSongs) {
            final artistId = await songsDao.getOrInsertArtist(dto.artist);
            final albumId = await songsDao.getOrInsertAlbum(
              dto.album,
              artistId,
              dto.coverArtPath,
              dto.year,
            );

            companions.add(
              SongsCompanion.insert(
                filePath: dto.filePath,
                title: dto.title,
                durationMs: dto.durationMs,
                format: dto.format,
                artistId: Value(artistId),
                albumId: Value(albumId),
                trackNumber: Value(dto.trackNumber),
              ),
            );
          }

          await songsDao.insertOrUpdateSongsBatch(companions);
          state = state.copyWith(
            isScanning: false,
            scannedCount: scannedSongs.length,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(isScanning: false, errorMessage: e.toString());
    }
  }
}

final libraryNotifierProvider =
    NotifierProvider<LibraryNotifier, LibraryState>(LibraryNotifier.new);

final songsStreamProvider = StreamProvider<List<Song>>((ref) {
  final songsDao = ref.watch(songsDaoProvider);
  return songsDao.watchAllSongs();
});
