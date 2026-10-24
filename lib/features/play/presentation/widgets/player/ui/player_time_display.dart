import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/core/utils/format_time_util.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([VideoUiNotifier, PlayStateNotifier])
class PlayerTimeDisplay extends ConsumerWidget {
  const PlayerTimeDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHorizontalDragging = ref.watch(
      videoUiProvider.select((state) => state.isHorizontalDragging),
    );
    final positionSeconds = isHorizontalDragging
        ? ref.watch(
            videoUiProvider.select((state) => state.dragPosition.inSeconds))
        : ref.watch(
            playStateProvider.select((state) => state.position.inSeconds));
    final durationSeconds = ref.watch(
      playStateProvider.select((state) => state.duration.inSeconds),
    );
    return Text(
      "${FormatTimeUtil.formatDuration(Duration(seconds: positionSeconds))} / ${FormatTimeUtil.formatDuration(Duration(seconds: durationSeconds))}",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
