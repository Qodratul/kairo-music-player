import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography.dart';
import '../providers/player_provider.dart';

/// Isolated Seekbar Component that listens locally to position stream.
/// Prevents parent screen re-renders during position updates.
class PlayerSeekbar extends ConsumerStatefulWidget {
  final Duration duration;
  final bool compact;

  const PlayerSeekbar({
    super.key,
    required this.duration,
    this.compact = false,
  });

  @override
  ConsumerState<PlayerSeekbar> createState() => _PlayerSeekbarState();
}

class _PlayerSeekbarState extends ConsumerState<PlayerSeekbar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: AudioService.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final currentMs = _dragValue?.toInt() ?? position.inMilliseconds;
        final maxMs = widget.duration.inMilliseconds > 0
            ? widget.duration.inMilliseconds
            : 1;

        if (widget.compact) {
          return SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
              trackHeight: 2,
              activeTrackColor: KairoColors.primary,
              inactiveTrackColor: KairoColors.surfaceBorder,
              thumbColor: KairoColors.primary,
            ),
            child: Slider(
              value: currentMs.clamp(0, maxMs).toDouble(),
              max: maxMs.toDouble(),
              onChanged: (val) {
                setState(() {
                  _dragValue = val;
                });
              },
              onChangeEnd: (val) {
                ref
                    .read(playerNotifierProvider.notifier)
                    .seek(Duration(milliseconds: val.toInt()));
                setState(() {
                  _dragValue = null;
                });
              },
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                trackHeight: 3,
                activeTrackColor: KairoColors.primary,
                inactiveTrackColor: KairoColors.surfaceBorder,
                thumbColor: KairoColors.primary,
              ),
              child: Slider(
                value: currentMs.clamp(0, maxMs).toDouble(),
                max: maxMs.toDouble(),
                onChanged: (val) {
                  setState(() {
                    _dragValue = val;
                  });
                },
                onChangeEnd: (val) {
                  ref
                      .read(playerNotifierProvider.notifier)
                      .seek(Duration(milliseconds: val.toInt()));
                  setState(() {
                    _dragValue = null;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(Duration(milliseconds: currentMs)),
                    style: KairoTypography.timestamp,
                  ),
                  Text(
                    _formatDuration(widget.duration),
                    style: KairoTypography.timestamp,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
