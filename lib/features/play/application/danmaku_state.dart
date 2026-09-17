import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';

enum DanmakuLoadStatus { waitingForVideo, loading, switching, idle, failed }

class DanmakuState {
  const DanmakuState({
    this.danmakus = const {},
    this.loadStatus = DanmakuLoadStatus.waitingForVideo,
    this.enabled = true,
    this.hiddenPlatforms = const {},
    this.epoch = 0,
  });

  final Map<int, List<Danmaku>> danmakus;
  final DanmakuLoadStatus loadStatus;
  final bool enabled;
  final Set<String> hiddenPlatforms;
  final int epoch;

  DanmakuState copyWith({
    Map<int, List<Danmaku>>? danmakus,
    DanmakuLoadStatus? loadStatus,
    bool? enabled,
    Set<String>? hiddenPlatforms,
    int? epoch,
  }) =>
      DanmakuState(
        danmakus: danmakus ?? this.danmakus,
        loadStatus: loadStatus ?? this.loadStatus,
        enabled: enabled ?? this.enabled,
        hiddenPlatforms: hiddenPlatforms ?? this.hiddenPlatforms,
        epoch: epoch ?? this.epoch,
      );
}

abstract interface class DanmakuStore {
  DanmakuState get value;
  void setLoadStatus(DanmakuLoadStatus value);
  void setDanmakus(Map<int, List<Danmaku>> value);
  void incrementEpoch();
  void clearDanmakus();
  void toggleEnabled();
  void setHiddenPlatforms(Set<String> value);
  void toggleHiddenPlatform(String platform);
}
