import 'package:anime_flow/pages/play/providers/play_provider.dart';
import 'package:anime_flow/pages/play/providers/video_ui_provider.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerTimeDisplay extends ConsumerWidget {
  const PlayerTimeDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHorizontalDragging = ref.watch(
      videoUiProvider.select((state) => state.isHorizontalDragging),
    );
    final dragPosition = ref.watch(
      videoUiProvider.select((state) => state.dragPosition),
    );
    final playState = ref.watch(playStateProvider);

    return Builder(builder: (context) {
      final position = isHorizontalDragging ? dragPosition : playState.position;
      final duration = playState.duration;

      return Text(
        "${FormatTimeUtil.formatDuration(position)} / ${FormatTimeUtil.formatDuration(duration)}",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      );
    });
  }
}
