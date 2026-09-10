import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/scanner_repository.dart';
import '../../domain/models/song_with_details.dart';

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
            // Multi-artist splitting: extract primary artist and individual artists
            final rawArtist = dto.artist ?? '';
            final artistList = rawArtist.isNotEmpty
                ? rawArtist.split(RegExp(r'\s*(?:/|&|;|,)\s*')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                : <String>[];

            final primaryArtistName = artistList.isNotEmpty ? artistList.first : (rawArtist.isNotEmpty ? rawArtist : null);

            // Register all individual artist names to populate clean Artists table
            int? primaryArtistId;
            for (final name in artistList) {
              final id = await songsDao.getOrInsertArtist(name);
              primaryArtistId ??= id;
            }
            if (primaryArtistId == null && primaryArtistName != null) {
              primaryArtistId = await songsDao.getOrInsertArtist(primaryArtistName);
            }

            final albumId = await songsDao.getOrInsertAlbum(
              dto.album,
              primaryArtistId,
              dto.coverArtPath,
              dto.year,
            );

            companions.add(
              SongsCompanion.insert(
                filePath: dto.filePath,
                title: dto.title,
                durationMs: dto.durationMs,
                format: dto.format,
                artistId: Value(primaryArtistId),
                albumId: Value(albumId),
                trackNumber: Value(dto.trackNumber),
                sampleRate: Value(dto.sampleRate),
                bitDepth: Value(dto.bitDepth),
                bitrate: Value(dto.bitrate),
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

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final songsWithDetailsStreamProvider = StreamProvider<List<SongWithDetails>>((ref) {
  final songsDao = ref.watch(songsDaoProvider);
  return songsDao.watchAllSongsWithDetails();
});

final albumsStreamProvider = StreamProvider<List<Album>>((ref) {
  final songsDao = ref.watch(songsDaoProvider);
  return songsDao.watchAllAlbums();
});

final artistsStreamProvider = StreamProvider<List<Artist>>((ref) {
  final songsDao = ref.watch(songsDaoProvider);
  return songsDao.watchAllArtists();
});

final playlistsStreamProvider = StreamProvider<List<Playlist>>((ref) {
  final songsDao = ref.watch(songsDaoProvider);
  return songsDao.watchAllPlaylists();
});

final filteredSongsProvider = Provider<AsyncValue<List<SongWithDetails>>>((ref) {
  final songsAsync = ref.watch(songsWithDetailsStreamProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return songsAsync.whenData((songs) {
    if (query.isEmpty) return songs;
    return songs
        .where((s) =>
            s.song.title.toLowerCase().contains(query) ||
            s.artistName.toLowerCase().contains(query) ||
            s.albumTitle.toLowerCase().contains(query) ||
            s.song.filePath.toLowerCase().contains(query))
        .toList();
  });
});

final filteredAlbumsProvider = Provider<AsyncValue<List<Album>>>((ref) {
  final albumsAsync = ref.watch(albumsStreamProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return albumsAsync.whenData((albums) {
    if (query.isEmpty) return albums;
    return albums.where((a) => a.title.toLowerCase().contains(query)).toList();
  });
});

final filteredArtistsProvider = Provider<AsyncValue<List<Artist>>>((ref) {
  final artistsAsync = ref.watch(artistsStreamProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return artistsAsync.whenData((artists) {
    if (query.isEmpty) return artists;
    return artists.where((a) => a.name.toLowerCase().contains(query)).toList();
  });
});
