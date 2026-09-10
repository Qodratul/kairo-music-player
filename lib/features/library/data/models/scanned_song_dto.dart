class ScannedSongDto {
  final String filePath;
  final String title;
  final String? artist;
  final String? album;
  final int durationMs;
  final int? trackNumber;
  final int? year;
  final String? coverArtPath;
  final String format;
  final int fileSize;
  final int? sampleRate;
  final int? bitDepth;
  final int? bitrate;

  ScannedSongDto({
    required this.filePath,
    required this.title,
    this.artist,
    this.album,
    required this.durationMs,
    this.trackNumber,
    this.year,
    this.coverArtPath,
    required this.format,
    required this.fileSize,
    this.sampleRate,
    this.bitDepth,
    this.bitrate,
  });
}
