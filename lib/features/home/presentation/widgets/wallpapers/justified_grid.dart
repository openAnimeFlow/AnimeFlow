import 'package:flutter/rendering.dart';

import 'justified_layout.dart';

/// 图片直接作为 sliver 子节点，换行只改变几何位置，不改变父节点。
class JustifiedGridDelegate extends SliverGridDelegate {
  const JustifiedGridDelegate(this.layout);

  final JustifiedGridLayout layout;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) => layout;

  @override
  bool shouldRelayout(JustifiedGridDelegate oldDelegate) =>
      oldDelegate.layout != layout;
}

class JustifiedGridLayout extends SliverGridLayout {
  factory JustifiedGridLayout(
    List<JustifiedImageRow> rows, {
    required double availableWidth,
    double spacing = 12,
    bool reverseCrossAxis = false,
  }) {
    final geometries = <SliverGridGeometry>[];
    var scrollOffset = 0.0;
    for (final row in rows) {
      var crossAxisOffset = 0.0;
      for (final width in row.widths) {
        geometries.add(SliverGridGeometry(
          scrollOffset: scrollOffset,
          crossAxisOffset: reverseCrossAxis
              ? availableWidth - crossAxisOffset - width
              : crossAxisOffset,
          // 子节点负责底部留白，使末行间距也计入准确的滚动范围。
          mainAxisExtent: row.imageHeight + spacing,
          crossAxisExtent: width,
        ));
        crossAxisOffset += width + spacing;
      }
      scrollOffset += row.imageHeight + spacing;
    }
    return JustifiedGridLayout._(List.unmodifiable(geometries));
  }

  const JustifiedGridLayout._(this._geometries);

  final List<SliverGridGeometry> _geometries;

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    var low = 0;
    var high = _geometries.length;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (_geometries[mid].trailingScrollOffset <= scrollOffset) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    var low = 0;
    var high = _geometries.length;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (_geometries[mid].scrollOffset < scrollOffset) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low > 0 ? low - 1 : 0;
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    if (index < _geometries.length) return _geometries[index];
    // RenderSliverGrid 会先查询几何信息，再尝试创建末尾/空列表子节点。
    return SliverGridGeometry(
      scrollOffset: computeMaxScrollOffset(_geometries.length),
      crossAxisOffset: 0,
      mainAxisExtent: 0,
      crossAxisExtent: 0,
    );
  }

  @override
  double computeMaxScrollOffset(int childCount) =>
      childCount == 0 || _geometries.isEmpty
          ? 0
          : _geometries[(childCount - 1).clamp(0, _geometries.length - 1)]
              .trailingScrollOffset;
}
