import 'package:anime_flow/core/settings/storage_key.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'danmaku_font_provider.g.dart';

/// 弹幕专用字体。为空时跟随项目主题字体。
@riverpod
class DanmakuFontFamily extends _$DanmakuFontFamily {
  @override
  String? build() => AppSettings.danmakuFontFamily;

  Future<void> setFamily(String? family) async {
    await AppSettings.setDanmakuValue(DanmakuKey.danmakuFontFamily, family);
    state = family;
  }
}

/// 是否在弹幕画布中应用项目或自定义字体。
@riverpod
class DanmakuFontEnabled extends _$DanmakuFontEnabled {
  @override
  bool build() => AppSettings.danmakuUseFont;

  Future<void> setEnabled(bool enabled) async {
    await AppSettings.setDanmakuValue(DanmakuKey.danmakuUseFont, enabled);
    state = enabled;
  }
}
