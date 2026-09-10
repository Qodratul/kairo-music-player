import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/theme/typography.dart';
import '../../player/presentation/providers/player_provider.dart';
import '../data/prompt_engine.dart';
import '../data/smart_playlist_repository.dart';
import '../domain/models/smart_playlist_query.dart';

/// Modal bottom sheet for Natural Language Smart Playlist Generation.
class SmartPlaylistSheet extends ConsumerStatefulWidget {
  const SmartPlaylistSheet({super.key});

  @override
  ConsumerState<SmartPlaylistSheet> createState() => _SmartPlaylistSheetState();
}

class _SmartPlaylistSheetState extends ConsumerState<SmartPlaylistSheet> {
  final TextEditingController _promptController = TextEditingController(
    text: 'Putar lagu rock klasik era 80-an yang sering aku dengar',
  );

  SmartPlaylistQuery? _parsedQuery;
  List<Song> _results = [];
  bool _isProcessing = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _generatePlaylist() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    final query = PromptEngine.parseNaturalLanguage(prompt);
    final db = ref.read(databaseProvider);
    final repo = SmartPlaylistRepository(db);

    final songs = await repo.executeSmartQuery(query);

    setState(() {
      _parsedQuery = query;
      _results = songs;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: KairoColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: KairoColors.primary),
                const SizedBox(width: 8),
                Text(
                  'AI Smart Playlist Generator',
                  style: KairoTypography.titleMedium.copyWith(color: KairoColors.primary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Misal: "Putar lagu rock klasik era 80-an yang sering aku dengar"',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: KairoColors.surfaceElevated,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: KairoColors.primary),
                  onPressed: _isProcessing ? null : _generatePlaylist,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_parsedQuery != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: KairoColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: KairoColors.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GENERATED STRUCTURED JSON QUERY:', style: KairoTypography.telemetryLabel),
                    const SizedBox(height: 4),
                    Text(
                      _parsedQuery!.toJson().toString(),
                      style: KairoTypography.telemetryValue.copyWith(color: KairoColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_isProcessing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_results.isNotEmpty) ...[
              Text('Found ${_results.length} tracks:', style: KairoTypography.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final song = _results[index];
                    return ListTile(
                      dense: true,
                      title: Text(song.title, style: KairoTypography.bodyMedium),
                      subtitle: Text(song.format.toUpperCase(), style: KairoTypography.bodySmall),
                      onTap: () {
                        ref.read(playerNotifierProvider.notifier).playAll(_results, initialIndex: index);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KairoColors.primary,
                    foregroundColor: KairoColors.background,
                  ),
                  onPressed: () {
                    ref.read(playerNotifierProvider.notifier).playAll(_results);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Generated Smart Playlist'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
