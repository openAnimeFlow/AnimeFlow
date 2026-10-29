import 'package:material_ui/material_ui.dart';

/// 内容顶部被悬浮组件遮挡的高度。
class TopOcclusionScope extends InheritedWidget {
  const TopOcclusionScope(
      {super.key, required this.height, required super.child})
      : assert(height >= 0);

  final double height;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TopOcclusionScope>()?.height ??
      0;

  @override
  bool updateShouldNotify(TopOcclusionScope oldWidget) =>
      height != oldWidget.height;
}
