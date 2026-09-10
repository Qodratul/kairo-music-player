/// Model representing a single timestamped line of synchronized lyrics.
class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });

  @override
  String toString() {
    return 'LyricLine(ts: ${timestamp.inMilliseconds}ms, text: $text)';
  }
}
