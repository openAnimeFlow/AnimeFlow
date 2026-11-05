String calculatePercentage(int value, int total) {
  if (total <= 0) {
    return '0%';
  }
  final percentage = (value / total) * 100;
  if (percentage >= 100) {
    return '100%';
  }
  // 保留1位小数，如果小数部分为0则显示整数
  if (percentage % 1 == 0) {
    return '${percentage.toInt()}%';
  }
  return '${percentage.toStringAsFixed(1)}%';
}

/// 网速格式化
String formatBytesPerSec(num bps) {
  final kb = bps / 1024.0;
  if (kb < 1024) return '${kb.toStringAsFixed(1)}KB/s';
  final mb = kb / 1024.0;
  return '${mb.toStringAsFixed(1)}MB/s';
}
