import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'image_preview_page.dart';

class AnimationNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final bool preview;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final BorderRadiusGeometry borderRadius;

  const AnimationNetworkImage({
    super.key,
    required this.url,
    this.fit,
    this.width,
    this.height,
    this.preview = false,
    this.borderRadius = BorderRadius.zero,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeOutDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    if (preview) {
      final heroTag = 'emoji_${url.hashCode}_${Random().nextInt(10000)}';
      return GestureDetector(
        onTap: () {
          ImageViewer.show(context, url,heroTag:  heroTag);
        },
        child: Hero(tag: heroTag, child: _buildImage()),
      );
    } else {
      return _buildImage();
    }
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: width,
        height: height,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
        placeholder: (context, url) {
          return const _ShimmerLoading();
        },
        errorWidget: (context, error, stackTrace) {
          return const Text('.');
        },
      ),
    );
  }
}

/// Shimmer 渐变加载动画组件
class _ShimmerLoading extends StatefulWidget {
  const _ShimmerLoading();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
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
        );
      },
    );
  }
}
