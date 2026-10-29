import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// 页面底部被悬浮组件覆盖的高度，包含覆盖区域内的设备安全区。
class BottomOcclusionScope extends InheritedWidget {
  const BottomOcclusionScope({
    super.key,
    required this.height,
    required super.child,
  }) : assert(height >= 0);

  final double height;

  static double of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BottomOcclusionScope>()
          ?.height ??
      0;

  @override
  bool updateShouldNotify(BottomOcclusionScope oldWidget) =>
      height != oldWidget.height;
}

/// 在滚动末尾自动留出被遮挡的空间。
class OcclusionAwareCustomScrollView extends CustomScrollView {
  const OcclusionAwareCustomScrollView({
    super.key,
    super.controller,
    super.slivers,
    super.physics,
    super.scrollBehavior,
    super.primary,
    super.shrinkWrap,
    super.reverse,
    super.restorationId,
  });

  @override
  List<Widget> buildSlivers(BuildContext context) => [
        ...super.buildSlivers(context),
        SliverToBoxAdapter(
          child: SizedBox(height: BottomOcclusionScope.of(context)),
        ),
      ];
}

/// 在保留系统键盘、底栏和提示条避让的同时，避开底部覆盖区域。
class OcclusionAwareFabLocation extends FloatingActionButtonLocation {
  const OcclusionAwareFabLocation(this.bottomOcclusion);

  final double bottomOcclusion;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final normal = FloatingActionButtonLocation.endFloat.getOffset(geometry);
    if (bottomOcclusion <= 0) return normal;
    final maximumY = geometry.scaffoldSize.height -
        bottomOcclusion -
        geometry.floatingActionButtonSize.height -
        kFloatingActionButtonMargin;
    return Offset(normal.dx, math.min(normal.dy, maximumY));
  }
}
