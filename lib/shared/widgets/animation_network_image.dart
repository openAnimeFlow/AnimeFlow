import 'package:anime_flow/core/utils/system_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

class AnimationNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit? fit;
  final Color? color;
  final double? width;
  final double? height;

  /// 加载占位的宽度，默认使用图片宽度，未设置图片宽度时使用 50。
  final double? placeholderWidth;

  /// 加载占位的高度，默认使用图片高度，未设置图片高度时使用 50。
  final double? placeholderHeight;

  /// 可选的内存解码宽度（物理像素），用于列表缩略图，保留图片比例。
  final int? memCacheWidth;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final FilterQuality filterQuality;
  final BorderRadiusGeometry borderRadius;
  final Alignment alignment;

  /// 图片解码后回传像素尺寸；设置 memCacheWidth 时为缩略图尺寸。
  final ValueChanged<Size>? onImageSize;

  const AnimationNetworkImage({
    super.key,
    required this.url,
    this.fit,
    this.width,
    this.height,
    this.placeholderWidth,
    this.placeholderHeight,
    this.memCacheWidth,
    this.borderRadius = BorderRadius.zero,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    this.color,
    this.onImageSize,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: memCacheWidth,
        color: color,
        alignment: alignment,
        filterQuality: filterQuality,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
        imageBuilder: onImageSize == null
            ? null
            : (context, provider) {
                // CachedNetworkImage 的 imageBuilder 提供原始 provider；必须
                // 与其内部使用同一个 ResizeImage，避免重新解码一份原图。
                final displayProvider =
                    ResizeImage.resizeIfNeeded(memCacheWidth, null, provider);
                return _ImageSizeReporter(
                  provider: displayProvider,
                  onImageSize: onImageSize!,
                  child: Image(
                    image: displayProvider,
                    width: width,
                    height: height,
                    fit: fit,
                    color: color,
                    alignment: alignment,
                    filterQuality: filterQuality,
                  ),
                );
              },
        placeholder: (context, url) {
          return _ShimmerLoading(
            width: placeholderWidth ?? width ?? 50,
            height: placeholderHeight ?? height ?? 50,
          );
        },
        errorWidget: (context, error, stackTrace) {
          return const Center(child: SizedBox.shrink());
        },
      ),
    );
  }
}

class _ImageSizeReporter extends StatefulWidget {
  const _ImageSizeReporter({
    required this.provider,
    required this.onImageSize,
    required this.child,
  });

  final ImageProvider provider;
  final ValueChanged<Size> onImageSize;
  final Widget child;

  @override
  State<_ImageSizeReporter> createState() => _ImageSizeReporterState();
}

class _ImageSizeReporterState extends State<_ImageSizeReporter> {
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener(
    _onImage,
    onError: (Object error, StackTrace? stack) {},
  );
  Size? _lastSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _ImageSizeReporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider != widget.provider) {
      _lastSize = null;
      _resolve();
    }
  }

  void _resolve() {
    final stream =
        widget.provider.resolve(createLocalImageConfiguration(context));
    if (_stream?.key == stream.key) return;
    _stream?.removeListener(_listener);
    _stream = stream;
    stream.addListener(_listener);
  }

  void _onImage(ImageInfo info, bool synchronousCall) {
    final size =
        Size(info.image.width.toDouble(), info.image.height.toDouble());
    info.dispose();
    if (_lastSize == size) return;
    _lastSize = size;
    final provider = widget.provider;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.provider == provider) widget.onImageSize(size);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Shimmer 渐变加载动画组件
class _ShimmerLoading extends StatefulWidget {
  const _ShimmerLoading({required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(); // 循环播放动画

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = SystemUtil.isDarkTheme(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [
                  _animation.value - 0.3,
                  _animation.value,
                  _animation.value + 0.3,
                ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
                colors: isDark
                    ? [Colors.grey[850]!, Colors.grey[700]!, Colors.grey[850]!]
                    : [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              ),
            ),
          ),
        );
      },
    );
  }
}
