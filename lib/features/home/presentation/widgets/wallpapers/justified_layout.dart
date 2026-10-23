class JustifiedImageRow {
  const JustifiedImageRow({
    required this.startIndex,
    required this.imageHeight,
    required this.widths,
  });

  final int startIndex;
  final double imageHeight;
  final List<double> widths;
}

/// 保留输入顺序；完整行填满容器，最后不足一行时不放大图片。
List<JustifiedImageRow> justifyImageRows(
  List<double> aspectRatios, {
  required double availableWidth,
  required double targetHeight,
  double spacing = 12,
  double minItemWidth = 0,
  int minItemsPerRow = 1,
  int? maxItemsPerRow,
}) {
  if (!availableWidth.isFinite || availableWidth <= 0 || aspectRatios.isEmpty) {
    return [];
  }
  assert(targetHeight > 0 && targetHeight.isFinite);
  assert(spacing >= 0 && spacing.isFinite);
  assert(minItemWidth >= 0 && minItemWidth.isFinite);
  assert(minItemsPerRow > 0);
  assert(maxItemsPerRow == null || maxItemsPerRow >= minItemsPerRow);
  final minimumWidth =
      minItemWidth < availableWidth ? minItemWidth : availableWidth;
  final ratios = aspectRatios
      .map((ratio) => ratio.isFinite && ratio > 0 ? ratio : 1.0)
      .toList(growable: false);
  final rows = <JustifiedImageRow>[];
  var start = 0;
  while (start < ratios.length) {
    var end = start;
    var sum = 0.0;
    var minRatio = double.infinity;
    var height = targetHeight;
    while (end < ratios.length) {
      final candidateSum = sum + ratios[end];
      final candidateMinRatio = ratios[end] < minRatio ? ratios[end] : minRatio;
      final candidateHeight =
          (availableWidth - spacing * (end - start)) / candidateSum;
      // 放入下一张前检查可读宽度，避免横图把竖图挤成窄条。
      // 最少张数优先于目标宽度，防止换行时只留下单张封面。
      if (end - start >= minItemsPerRow &&
          ((maxItemsPerRow != null && end - start >= maxItemsPerRow) ||
              candidateHeight * candidateMinRatio < minimumWidth)) {
        height = (availableWidth - spacing * (end - start - 1)) / sum;
        break;
      }
      sum += ratios[end];
      minRatio = candidateMinRatio;
      end++;
      height = (availableWidth - spacing * (end - start - 1)) / sum;
      if (height <= targetHeight && end - start >= minItemsPerRow) {
        if (end - start > minItemsPerRow) {
          final previousSum = sum - ratios[end - 1];
          final previousHeight =
              (availableWidth - spacing * (end - start - 2)) / previousSum;
          if (height <= 0 ||
              (previousHeight - targetHeight).abs() <
                  (height - targetHeight).abs()) {
            end--;
            height = previousHeight;
          }
        }
        break;
      }
    }
    final remaining = ratios.length - end;
    if (remaining > 0 && remaining < minItemsPerRow) {
      final needed = minItemsPerRow - remaining;
      // 优先借出图片组成下一行；借出后不足最少张数时，将尾图合并进本行。
      end =
          end - start - needed >= minItemsPerRow ? end - needed : ratios.length;
      sum = 0;
      minRatio = double.infinity;
      for (var i = start; i < end; i++) {
        sum += ratios[i];
        if (ratios[i] < minRatio) minRatio = ratios[i];
      }
      height = (availableWidth - spacing * (end - start - 1)) / sum;
    }
    final isShortLastRow = end == ratios.length && height > targetHeight;
    if (isShortLastRow) {
      final minimumHeight = minimumWidth / minRatio;
      final preferredHeight =
          minimumHeight > targetHeight ? minimumHeight : targetHeight;
      if (height > preferredHeight) height = preferredHeight;
    }
    final widths = <double>[];
    for (var i = start; i < end; i++) {
      // 用剩余宽度计算最后一张，避免浮点累积造成行尾溢出。
      widths.add(i == end - 1 && !isShortLastRow
          ? availableWidth -
              spacing * (end - start - 1) -
              widths.fold(0.0, (sum, width) => sum + width)
          : height * ratios[i]);
    }
    rows.add(JustifiedImageRow(
      startIndex: start,
      imageHeight: height,
      widths: List.unmodifiable(widths),
    ));
    start = end;
  }
  return rows;
}
