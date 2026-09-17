import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/play/application/danmaku_state.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'danmaku_state_provider.g.dart';

@Riverpod(keepAlive: true, dependencies: [playExtra])
class DanmakuStateNotifier extends _$DanmakuStateNotifier
    implements DanmakuStore {
  @override
  DanmakuState build() {
    ref.watch(playExtraProvider);
    return DanmakuState(
      enabled: AppSettings.danmakuOn,
      hiddenPlatforms: loadHiddenPlatformsFromStorage(),
    );
  }

  @override
  DanmakuState get value => state;

  @override
  void setLoadStatus(DanmakuLoadStatus value) {
    state = state.copyWith(loadStatus: value);
  }

  @override
  void setDanmakus(Map<int, List<Danmaku>> value) {
    state = state.copyWith(danmakus: value);
  }

  @override
  void incrementEpoch() {
    state = state.copyWith(epoch: state.epoch + 1);
  }

  @override
  void clearDanmakus() {
    state = state.copyWith(danmakus: const {});
  }

  @override
  void toggleEnabled() {
    state = state.copyWith(enabled: !state.enabled);
  }

  @override
  void setHiddenPlatforms(Set<String> value) {
    state = state.copyWith(hiddenPlatforms: value);
  }

  @override
  void toggleHiddenPlatform(String platform) {
    final next = {...state.hiddenPlatforms};
    if (!next.remove(platform)) next.add(platform);
    state = state.copyWith(hiddenPlatforms: next);
  }
}

Set<String> loadHiddenPlatformsFromStorage() => {
      if (!AppSettings.danmakuPlatformBilibili) 'BiliBili',
      if (!AppSettings.danmakuPlatformGamer) 'Gamer',
      if (!AppSettings.danmakuPlatformDanDanPlay) '弹弹Play',
    };
