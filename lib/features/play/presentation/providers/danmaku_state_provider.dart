import 'package:anime_flow/features/play/application/danmaku_state.dart';
import 'package:anime_flow/features/play/domain/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'danmaku_state_provider.g.dart';

@Riverpod(dependencies: [playExtra])
class DanmakuStateNotifier extends _$DanmakuStateNotifier
    implements DanmakuStore {
  @override
  DanmakuState build() {
    ref.watch(playExtraProvider);
    return DanmakuState(
      enabled: ref.read(playPreferencesProvider).danmakuOn,
      hiddenPlatforms: {
        if (!ref.read(playPreferencesProvider).danmakuPlatformBilibili)
          'BiliBili',
        if (!ref.read(playPreferencesProvider).danmakuPlatformGamer) 'Gamer',
        if (!ref.read(playPreferencesProvider).danmakuPlatformDanDanPlay)
          '弹弹Play',
      },
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

@Riverpod(keepAlive: true)
class DanmakuChineseModeNotifier extends _$DanmakuChineseModeNotifier {
  @override
  DanmakuChineseMode build() {
    return DanmakuChineseMode.fromName(
      ref.read(playPreferencesProvider).danmakuChineseMode,
    );
  }

  void setMode(DanmakuChineseMode mode) {
    state = mode;
    ref.read(playPreferencesProvider).setDanmakuChineseMode(mode.name);
  }
}
