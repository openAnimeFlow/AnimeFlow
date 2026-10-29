import 'dart:async';

import 'package:anime_flow/features/play/application/player_bindings.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_cache_speed_provider.g.dart';

/// 仅缓冲指示器可见且有订阅者时采样。
@Riverpod(dependencies: [VideoUiNotifier, PlayStateNotifier, playSession])
Stream<double?> playerCacheSpeed(Ref ref) {
  final indicator = ref.watch(
    videoUiProvider.select((state) => state.centerIndicator),
  );
  final playback = ref.watch(playStateProvider.select(
        (state) => (kernel: state.kernel, switching: state.switchingKernel),
  ));
  if (indicator != VideoControlsIndicatorType.bufferingIndicator ||
      playback.kernel != PlayerKernel.mediaKit ||
      playback.switching) {
    return Stream.value(null);
  }

  final coordinator = ref.watch(playSessionProvider).playbackCoordinator;
  final controller = StreamController<double?>();
  Timer? timer;
  var active = true;
  var reading = false;

  Future<void> sample() async {
    if (!active || reading) return;
    reading = true;
    try {
      final speed = await coordinator.readCacheSpeed();
      if (active) controller.add(speed);
    } catch (_) {
      if (active) controller.add(null);
    } finally {
      reading = false;
    }
  }

  void start() {
    active = true;
    unawaited(sample());
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(sample());
    });
  }

  void stop() {
    active = false;
    timer?.cancel();
    timer = null;
  }

  controller.onListen = start;
  ref.onCancel(stop);
  ref.onResume(start);
  ref.onDispose(() {
    stop();
    unawaited(controller.close());
  });
  return controller.stream;
}
