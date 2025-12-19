import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImagePreviewPage extends StatefulWidget {
  final String imageUrl;
  final String heroTag;

  const ImagePreviewPage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  double _dragOffset = 0.0;
  late PhotoViewController _photoViewController;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController();
    _photoViewController.outputStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentScale = state.scale ?? 1.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgOpacity = (1 - (_dragOffset / 300)).clamp(0.0, 1.0);
    // 只有在缩放接近初始状态时才允许垂直滑动关闭
    final canDismiss = _currentScale <= 1.1;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: bgOpacity * 0.8),
      body: GestureDetector(
        onVerticalDragUpdate: canDismiss
            ? (details) {
                setState(() {
                  _dragOffset += details.delta.dy;
                });
              }
            : null,
        onVerticalDragEnd: canDismiss
            ? (details) {
                if (_dragOffset > 120) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _dragOffset = 0;
                  });
                }
              }
            : null,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Hero(
              tag: widget.heroTag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PhotoView(
                  controller: _photoViewController,
                  enableRotation: false,
                  tightMode: true,
                  imageProvider: NetworkImage(widget.imageUrl),
                  backgroundDecoration:
                  const BoxDecoration(color: Colors.transparent),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                ),
              )
            ),
          ),
        ),
      ),
    );
  }
}

class TransparentImageRoute extends PageRouteBuilder {
  final String imageUrl;
  final String heroTag;

  TransparentImageRoute({
    required this.imageUrl,
    required this.heroTag,
  }) : super(
          opaque: false, // 允许看到下层页面
          barrierColor: Colors.black.withValues(alpha: 0.2),
          pageBuilder: (_, __, ___) {
            return ImagePreviewPage(
              imageUrl: imageUrl,
              heroTag: heroTag,
            );
          },
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}
