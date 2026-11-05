/// 弹幕简体/繁体转换模式。
enum DanmakuChineseMode {
  none('none'),
  s2t('s2t'),
  t2s('t2s');

  const DanmakuChineseMode(this.name);

  /// 用于持久化的枚举名。
  final String name;

  static DanmakuChineseMode fromName(String? value) {
    return values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => DanmakuChineseMode.none,
    );
  }
}
