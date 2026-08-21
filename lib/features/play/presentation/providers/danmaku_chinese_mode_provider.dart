import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'danmaku_chinese_mode_provider.g.dart';

@Riverpod(keepAlive: true)
class DanmakuChineseModeNotifier extends _$DanmakuChineseModeNotifier {
  @override
  DanmakuChineseMode build() {
    return DanmakuChineseMode.fromName(
      Storage.setting.get(
        DanmakuKey.danmakuChineseMode,
        defaultValue: DanmakuChineseMode.none.name,
      ),
    );
  }

  void setMode(DanmakuChineseMode mode) {
    state = mode;
    Storage.setting.put(DanmakuKey.danmakuChineseMode, mode.name);
  }
}
