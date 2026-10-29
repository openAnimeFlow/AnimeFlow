import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

class AnimationNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit? fit;
  final Color? color;
  final double? width;
  final double? height;

  /// 加载占位的宽度。
  final double? placeholderWidth;

  /// 加载占位的高度。
  final double? placeholderHeight;

  /// 可选的内存解码宽度（物理像素），用于列表缩略图，保留图片比例。
  final int? memCacheWidth;

  /// 仅在同一 URL 的解码尺寸改变时保留旧图，切换 URL 时重新加载。
  final bool gaplessResize;
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
    this.gaplessResize = false,
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
        key: gaplessResize ? ValueKey(url) : null,
        imageUrl: url,
        useOldImageOnUrlChange: gaplessResize,
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
            width: placeholderWidth ?? 0,
            height: placeholderHeight ?? 0,
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
class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = Color.lerp(
      baseColor,
      isDark ? colorScheme.onSurface : colorScheme.surface,
      isDark ? 0.08 : 0.65,
    )!;

    return SizedBox(
      width: width,
      height: height,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: ColoredBox(color: baseColor),
      ),
    );
  }
}
