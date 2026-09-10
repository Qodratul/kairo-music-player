/// Structured JSON Model for Edge AI Natural Language Smart Playlist Generation.
class SmartPlaylistQuery {
  final String tempo; // 'slow' | 'medium' | 'fast' | 'any'
  final List<String> genres;
  final List<int>? releaseYearRange; // [startYear, endYear]
  final String sortBy; // 'last_played' | 'play_count' | 'duration' | 'energy'
  final int limit;

  const SmartPlaylistQuery({
    this.tempo = 'any',
    this.genres = const [],
    this.releaseYearRange,
    this.sortBy = 'play_count',
    this.limit = 25,
  });

  factory SmartPlaylistQuery.fromJson(Map<String, dynamic> json) {
    List<int>? yearRange;
    if (json['release_year_range'] != null && json['release_year_range'] is List) {
      final list = json['release_year_range'] as List;
      if (list.length >= 2) {
        yearRange = [
          (list[0] as num).toInt(),
          (list[1] as num).toInt(),
        ];
      }
    }

    return SmartPlaylistQuery(
      tempo: json['tempo']?.toString() ?? 'any',
      genres: (json['genres'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      releaseYearRange: yearRange,
      sortBy: json['sort_by']?.toString() ?? 'play_count',
      limit: (json['limit'] as num?)?.toInt() ?? 25,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tempo': tempo,
      'genres': genres,
      'release_year_range': releaseYearRange,
      'sort_by': sortBy,
      'limit': limit,
    };
  }

  @override
  String toString() {
    return 'SmartPlaylistQuery(tempo: $tempo, genres: $genres, years: $releaseYearRange, sortBy: $sortBy, limit: $limit)';
  }
}
