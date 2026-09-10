import 'dart:io';

import 'models/lyric_line.dart';

/// Robust parser for .lrc (LyRiCs) format files.
class LrcParser {
  static final RegExp _timestampRegExp =
      RegExp(r'\[(\d+):(\d+)(?:[\.\:](\d+))?\]');

  /// Parses raw LRC string content into a list of sorted [LyricLine]s.
  static List<LyricLine> parse(String content) {
    final List<LyricLine> lines = [];

    for (var rawLine in content.split('\n')) {
      rawLine = rawLine.trim();
      if (rawLine.isEmpty) continue;

      final matches = _timestampRegExp.allMatches(rawLine).toList();
      if (matches.isEmpty) continue;

      final text = rawLine.replaceAll(_timestampRegExp, '').trim();

      for (final match in matches) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final subSecondStr = match.group(3) ?? '0';

        int milliseconds = 0;
        if (subSecondStr.length == 2) {
          milliseconds = int.parse(subSecondStr) * 10;
        } else if (subSecondStr.length == 3) {
          milliseconds = int.parse(subSecondStr);
        } else if (subSecondStr.length == 1) {
          milliseconds = int.parse(subSecondStr) * 100;
        }

        final duration = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        lines.add(LyricLine(timestamp: duration, text: text));
      }
    }

    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }

  /// Reads and parses the .lrc file corresponding to [songFilePath].
  static Future<List<LyricLine>> parseForSongFile(String songFilePath) async {
    try {
      final dotIndex = songFilePath.lastIndexOf('.');
      final lrcPath = (dotIndex != -1)
          ? '${songFilePath.substring(0, dotIndex)}.lrc'
          : '$songFilePath.lrc';

      final lrcFile = File(lrcPath);
      if (await lrcFile.exists()) {
        final content = await lrcFile.readAsString();
        return parse(content);
      }
    } catch (_) {
      // Ignore reading error if file does not exist or cannot be read
    }
    return [];
  }
}
