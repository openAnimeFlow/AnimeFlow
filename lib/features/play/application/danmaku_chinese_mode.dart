import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';

/// 弹幕简体/繁体转换模式。
enum DanmakuChineseMode {
  none('none'),
  s2t('s2t'),
  t2s('t2s');

  const DanmakuChineseMode(this.name);

  /// 用于持久化的枚举名。
  final String name;

  /// 对应的 OpenCC 配置；[DanmakuChineseMode.none] 时为 null。
  OpenCCConfig? get config => switch (this) {
        DanmakuChineseMode.none => null,
        DanmakuChineseMode.s2t => OpenCCConfig.s2t,
        DanmakuChineseMode.t2s => OpenCCConfig.t2s,
      };

  static DanmakuChineseMode fromName(String? value) {
    return values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => DanmakuChineseMode.none,
    );
  }
}
