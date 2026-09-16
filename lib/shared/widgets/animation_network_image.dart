import 'package:anime_flow/core/utils/system_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AnimationNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit? fit;
  final Color? color;
  final double? width;
  final double? height;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final FilterQuality filterQuality;
  final BorderRadiusGeometry borderRadius;
  final Alignment alignment;

  const AnimationNetworkImage({
    super.key,
    required this.url,
    this.fit,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    this.color,
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
        color: color,
        alignment: alignment,
        filterQuality: filterQuality,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
        placeholder: (context, url) {
          return _ShimmerLoading(
            width: width ?? 50,
            height: height ?? 50,
          );
        },
        errorWidget: (context, error, stackTrace) {
          return const Center(child: SizedBox.shrink());
        },
      ),
    );
  }
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
