import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_taglib/flutter_taglib.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/isolate_runner.dart';
import 'models/scanned_song_dto.dart';

class ScannerParams {
  final List<String> searchDirectories;
  final String cacheDirectoryPath;

  const ScannerParams({
    required this.searchDirectories,
    required this.cacheDirectoryPath,
  });
}

class ScannerRepository {
  /// Scans directories recursively for audio files and extracts metadata using flutter_taglib.
  /// Uses [IsolateRunner] to run computation off the main thread.
  Future<Either<String, List<ScannedSongDto>>> scanDirectories(
    List<String> directories,
    String cacheDirPath,
  ) {
    final params = ScannerParams(
      searchDirectories: directories,
      cacheDirectoryPath: cacheDirPath,
    );
    return IsolateRunner.run(_scanTask, params);
  }

  static Future<List<ScannedSongDto>> _scanTask(ScannerParams params) async {
    final List<ScannedSongDto> scannedSongs = [];
    final cacheDir = Directory(p.join(params.cacheDirectoryPath, 'covers'));
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }

    final supportedExtensions = ['.mp3', '.flac', '.m4a', '.wav', '.ogg', '.aac', '.opus', '.wma'];

    for (final dirPath in params.searchDirectories) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;

      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (supportedExtensions.contains(ext)) {
            try {
              final tagFile = TagLibFile.open(entity.path);
              if (tagFile == null) continue;

              try {
                String? coverArtPath;

                // Priority 1: Embedded picture in TagLib
                final coverBytes = tagFile.coverData;
                if (coverBytes != null && coverBytes.isNotEmpty) {
                  String extImg = '.jpg';
                  final mime = tagFile.coverMimeType?.toLowerCase() ?? '';
                  if (mime.contains('png')) {
                    extImg = '.png';
                  }

                  final hash = md5.convert(coverBytes).toString();
                  final coverFile = File(p.join(cacheDir.path, '$hash$extImg'));

                  if (!coverFile.existsSync()) {
                    coverFile.writeAsBytesSync(coverBytes);
                  }
                  coverArtPath = coverFile.path;
                }

                // Priority 2: Fallback to image files in the same directory (cover.jpg, folder.jpg, etc.)
                if (coverArtPath == null) {
                  final songDir = Directory(p.dirname(entity.path));
                  if (songDir.existsSync()) {
                    final candidates = [
                      'cover.jpg',
                      'cover.jpeg',
                      'cover.png',
                      'folder.jpg',
                      'folder.jpeg',
                      'folder.png',
                      'album.jpg',
                      'album.png',
                    ];
                    for (final name in candidates) {
                      final imgFile = File(p.join(songDir.path, name));
                      if (imgFile.existsSync()) {
                        coverArtPath = imgFile.path;
                        break;
                      }
                    }
                  }
                }

                final fallbackTitle = p.basenameWithoutExtension(entity.path);
                final title = tagFile.title.trim().isNotEmpty ? tagFile.title.trim() : fallbackTitle;
                final artist = tagFile.artist.trim().isNotEmpty ? tagFile.artist.trim() : null;
                final album = tagFile.album.trim().isNotEmpty ? tagFile.album.trim() : null;
                final durationMs = tagFile.duration.inMilliseconds;
                final trackNumber = tagFile.track > 0 ? tagFile.track : null;
                final year = tagFile.year > 0 ? tagFile.year : null;

                final fileExt = ext.replaceAll('.', '').toUpperCase();
                final format = (tagFile.format?.isNotEmpty == true)
                    ? tagFile.format!.toUpperCase()
                    : fileExt;

                final sampleRate = tagFile.sampleRate > 0 ? tagFile.sampleRate : 44100;
                final bitrate = tagFile.bitrate > 0 ? tagFile.bitrate : 320;
                final isLossless = tagFile.isLossless ?? (fileExt == 'FLAC' || fileExt == 'WAV');
                final bitDepth = isLossless ? 24 : 16;

                scannedSongs.add(ScannedSongDto(
                  filePath: entity.path,
                  title: title,
                  artist: artist,
                  album: album,
                  durationMs: durationMs,
                  trackNumber: trackNumber,
                  year: year,
                  coverArtPath: coverArtPath,
                  format: format,
                  fileSize: entity.lengthSync(),
                  sampleRate: sampleRate,
                  bitDepth: bitDepth,
                  bitrate: bitrate,
                ));
              } finally {
                tagFile.close();
              }
            } catch (e) {
              // Ignore file if metadata reading fails, just continue scanning
              continue;
            }
          }
        }
      }
    }

    return scannedSongs;
  }
}
