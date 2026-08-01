/// 收藏类型枚举
///
/// 数值与 Bangumi API [SubjectCollectionType] 一致：
/// 1=想看, 2=看过, 3=在看, 4=搁置, 5=抛弃
enum CollectType {
  /// 未收藏
  none(0, '未收藏'),

  /// 想看
  planToWatch(1, '想看'),

  /// 看过
  watched(2, '看过'),

  /// 在看
  watching(3, '在看'),

  /// 搁置
  onHold(4, '搁置'),

  /// 抛弃
  abandoned(5, '抛弃');

  const CollectType(this.value, this.label);

  /// 数值表示
  final int value;

  /// 显示标签
  final String label;

  /// 根据数值获取枚举
  static CollectType fromValue(int value) {
    return CollectType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CollectType.none,
    );
  }

  /// 是否为有效的收藏状态（排除未收藏）
  bool get isCollected => this != CollectType.none;
}
