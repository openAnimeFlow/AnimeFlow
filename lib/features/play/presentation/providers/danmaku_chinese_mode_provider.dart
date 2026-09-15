import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'danmaku_chinese_mode_provider.g.dart';

@Riverpod(keepAlive: true)
class DanmakuChineseModeNotifier extends _$DanmakuChineseModeNotifier {
  @override
  DanmakuChineseMode build() {
    return DanmakuChineseMode.fromName(
      AppSettings.danmakuChineseMode,
    );
  }

  void setMode(DanmakuChineseMode mode) {
    state = mode;
    AppSettings.setDanmakuChineseMode(mode.name);
  }
}
