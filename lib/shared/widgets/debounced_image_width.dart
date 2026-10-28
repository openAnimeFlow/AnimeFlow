import 'dart:async';

import 'package:flutter/widgets.dart';

/// 只延迟图片解码尺寸，卡片布局仍立即响应窗口变化。
class DebouncedImageWidth extends StatefulWidget {
  const DebouncedImageWidth(
      {super.key, required this.width, required this.builder});

  /// 图片显示宽度（逻辑像素），内部结合屏幕像素密度计算解码宽度。
  final double width;
  final Widget Function(BuildContext context, int cacheWidth) builder;

  @override
  State<DebouncedImageWidth> createState() => _DebouncedImageWidthState();
}

class _DebouncedImageWidthState extends State<DebouncedImageWidth> {
  Timer? _resizeDebounce;
  double? _pixelRatio;
  late int _cacheWidth;

  int _calculateCacheWidth() =>
      (widget.width * _pixelRatio!).ceil().clamp(1, 4096);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final firstBuild = _pixelRatio == null;
    if (_pixelRatio == pixelRatio) return;
    _pixelRatio = pixelRatio;
    if (firstBuild) {
      _cacheWidth = _calculateCacheWidth();
    } else {
      _scheduleResize();
    }
  }

  @override
  void didUpdateWidget(covariant DebouncedImageWidth oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width) _scheduleResize();
  }

  void _scheduleResize() {
    _resizeDebounce?.cancel();
    _resizeDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      final width = _calculateCacheWidth();
      if (width != _cacheWidth) setState(() => _cacheWidth = width);
    });
  }

  @override
  void dispose() {
    _resizeDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _cacheWidth);
}
