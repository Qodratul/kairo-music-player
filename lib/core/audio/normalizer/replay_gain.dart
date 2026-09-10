/// Data structure and parser for ReplayGain 2.0 metadata tags.
class ReplayGainData {
  final double? trackGainDb;
  final double? trackPeak;
  final double? albumGainDb;
  final double? albumPeak;

  const ReplayGainData({
    this.trackGainDb,
    this.trackPeak,
    this.albumGainDb,
    this.albumPeak,
  });

  bool get hasTrackGain => trackGainDb != null;
  bool get hasAlbumGain => albumGainDb != null;
  bool get hasAnyGain => hasTrackGain || hasAlbumGain;

  /// Parses ReplayGain tags from a TagLib or metadata properties map.
  factory ReplayGainData.fromProperties(Map<String, List<String>> properties) {
    double? parseDb(String? value) {
      if (value == null) return null;
      final clean = value.toUpperCase().replaceAll('DB', '').trim();
      return double.tryParse(clean);
    }

    double? parsePeak(String? value) {
      if (value == null) return null;
      return double.tryParse(value.trim());
    }

    String? getFirst(String key) {
      final list = properties[key] ?? properties[key.toUpperCase()];
      if (list != null && list.isNotEmpty) {
        return list.first;
      }
      return null;
    }

    return ReplayGainData(
      trackGainDb: parseDb(getFirst('REPLAYGAIN_TRACK_GAIN')),
      trackPeak: parsePeak(getFirst('REPLAYGAIN_TRACK_PEAK')),
      albumGainDb: parseDb(getFirst('REPLAYGAIN_ALBUM_GAIN')),
      albumPeak: parsePeak(getFirst('REPLAYGAIN_ALBUM_PEAK')),
    );
  }

  @override
  String toString() {
    return 'ReplayGainData(trackGainDb: $trackGainDb dB, trackPeak: $trackPeak, albumGainDb: $albumGainDb dB, albumPeak: $albumPeak)';
  }
}
