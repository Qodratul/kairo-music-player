import 'dart:convert';

import '../domain/models/smart_playlist_query.dart';

/// On-Device Structured Prompt Engine converting natural language queries to structured JSON.
class PromptEngine {
  /// System prompt template for on-device Small Language Model (SLM) guidance.
  static String get systemPromptGuidance => '''
Anda adalah mesin penyusun parameter pemutar musik. Terjemahkan permintaan pengguna 
menjadi format JSON valid tanpa teks penjelasan tambahan.

Skema JSON:
{
  "tempo": "slow" | "medium" | "fast" | "any",
  "genres": string[],
  "release_year_range": [number, number] | null,
  "sort_by": "last_played" | "play_count" | "duration" | "energy",
  "limit": number
}
''';

  /// Deterministic offline parser translating natural language queries to structured [SmartPlaylistQuery].
  static SmartPlaylistQuery parseNaturalLanguage(String prompt) {
    final lower = prompt.toLowerCase().trim();

    // 1. Release Year / Era Detection
    List<int>? yearRange;
    if (lower.contains('80') || lower.contains('80an') || lower.contains('80s') || lower.contains('1980')) {
      yearRange = [1980, 1989];
    } else if (lower.contains('90') || lower.contains('90an') || lower.contains('90s') || lower.contains('1990')) {
      yearRange = [1990, 1999];
    } else if (lower.contains('2000') || lower.contains('2000an') || lower.contains('00s')) {
      yearRange = [2000, 2009];
    } else if (lower.contains('2010') || lower.contains('2010an') || lower.contains('10s')) {
      yearRange = [2010, 2019];
    } else if (lower.contains('2020') || lower.contains('2020an') || lower.contains('20s')) {
      yearRange = [2020, 2029];
    } else if (lower.contains('klasik') || lower.contains('classic') || lower.contains('70')) {
      yearRange = [1970, 1979];
    }

    // 2. Tempo Detection
    String tempo = 'any';
    if (lower.contains('lambat') || lower.contains('slow') || lower.contains('santai') || lower.contains('akustik')) {
      tempo = 'slow';
    } else if (lower.contains('cepat') || lower.contains('fast') || lower.contains('semangat') || lower.contains('olahraga') || lower.contains('workout')) {
      tempo = 'fast';
    } else if (lower.contains('sedang') || lower.contains('medium')) {
      tempo = 'medium';
    }

    // 3. Genre Detection
    final genres = <String>[];
    if (lower.contains('rock')) genres.add('Rock');
    if (lower.contains('pop')) genres.add('Pop');
    if (lower.contains('jazz')) genres.add('Jazz');
    if (lower.contains('metal')) genres.add('Metal');
    if (lower.contains('indie')) genres.add('Indie');
    if (lower.contains('hip hop') || lower.contains('hiphop') || lower.contains('rap')) genres.add('Hip-Hop');
    if (lower.contains('r&b') || lower.contains('rnb')) genres.add('R&B');
    if (lower.contains('electronic') || lower.contains('edm')) genres.add('Electronic');

    // 4. Sorting Preference Detection
    String sortBy = 'play_count';
    if (lower.contains('baru') || lower.contains('terakhir') || lower.contains('last played') || lower.contains('recent')) {
      sortBy = 'last_played';
    } else if (lower.contains('sering') || lower.contains('populer') || lower.contains('favorit') || lower.contains('most played')) {
      sortBy = 'play_count';
    } else if (lower.contains('panjang') || lower.contains('durasi')) {
      sortBy = 'duration';
    } else if (lower.contains('energi') || lower.contains('energy')) {
      sortBy = 'energy';
    }

    // 5. Limit Detection
    int limit = 25;
    final limitMatch = RegExp(r'(\d+)\s*(lagu|song|track)').firstMatch(lower);
    if (limitMatch != null) {
      limit = int.tryParse(limitMatch.group(1)!) ?? 25;
    }

    return SmartPlaylistQuery(
      tempo: tempo,
      genres: genres,
      releaseYearRange: yearRange,
      sortBy: sortBy,
      limit: limit,
    );
  }

  /// Parses a raw JSON string returned from local SLM model output.
  static SmartPlaylistQuery? parseJsonOutput(String jsonOutput) {
    try {
      final startIndex = jsonOutput.indexOf('{');
      final endIndex = jsonOutput.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final cleanJson = jsonOutput.substring(startIndex, endIndex + 1);
        final Map<String, dynamic> parsed = json.decode(cleanJson);
        return SmartPlaylistQuery.fromJson(parsed);
      }
    } catch (_) {
      // Return null on JSON parsing error
    }
    return null;
  }
}
