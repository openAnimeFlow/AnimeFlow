library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Full-screen image preview. Navigation is registered in [ImagePreviewRoute].
class ImageViewer extends StatefulWidget {
  ImageViewer({
    super.key,
    required List<String> imageUrls,
    this.initialIndex = 0,
    this.heroTag,
  }) : imageUrls = List.unmodifiable(imageUrls);

  final List<String> imageUrls;
  final int initialIndex;
  final Object? heroTag;

  static Object heroTagFor(String imageUrl, int index) => '$imageUrl-$index';

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  static const _wheelScaleStep = 1.1;
  static const _minScaleFactor = 1.0;
  static const _maxScaleFactor = 6.0;

  late final PageController _pageController;
  late int _currentIndex;
  final Map<int, PhotoViewController> _controllers = {};
  final Map<int, PhotoViewScaleStateController> _scaleControllers = {};
  final Map<int, double> _initialScales = {};

  bool get _isGallery => widget.imageUrls.length > 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final controller in _scaleControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final controller = _controllers[_currentIndex];
    final scaleController = _scaleControllers[_currentIndex];
    if (controller == null || scaleController == null) return;

    final current = controller.scale ?? _initialScales[_currentIndex] ?? 1.0;
    _initialScales[_currentIndex] ??= current;
    final factor =
        event.scrollDelta.dy < 0 ? _wheelScaleStep : 1 / _wheelScaleStep;
    final min = _initialScales[_currentIndex]! * _minScaleFactor;
    final max = _initialScales[_currentIndex]! * _maxScaleFactor;
    final next = (current * factor).clamp(min, max);
    if (next == current) return;
    controller.scale = next;
    scaleController.scaleState = PhotoViewScaleState.zoomedIn;
  }

  void _close() => Navigator.of(context).pop();

  void _goToPreviousImage() {
    if (_currentIndex == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextImage() {
    if (_currentIndex == widget.imageUrls.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.82),
      body: Listener(
        onPointerSignal: _handlePointerSignal,
        child: Stack(
          children: [
            GestureDetector(
              onTap: _close,
              child: _content(),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _close,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
            if (_isGallery)
              Positioned(
                bottom: MediaQuery.paddingOf(context).bottom + 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            if (SystemUtil.isDesktop && _isGallery) ...[
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildNavButton(
                    icon: Icons.chevron_left,
                    onPressed: _currentIndex > 0 ? _goToPreviousImage : null,
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildNavButton(
                    icon: Icons.chevron_right,
                    onPressed: _currentIndex < widget.imageUrls.length - 1
                        ? _goToNextImage
                        : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (_isGallery) {
      return PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        builder: _page,
      );
    }

    final controller = _controllers.putIfAbsent(0, PhotoViewController.new);
    final scaleController = _scaleControllers.putIfAbsent(
      0,
      PhotoViewScaleStateController.new,
    );
    return PhotoView(
      imageProvider: CachedNetworkImageProvider(widget.imageUrls.first),
      controller: controller,
      scaleStateController: scaleController,
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      heroAttributes: widget.heroTag == null
          ? null
          : PhotoViewHeroAttributes(tag: widget.heroTag!),
      loadingBuilder: (context, event) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorBuilder: (context, error, stackTrace) => _error(),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed == null ? Colors.white38 : Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _error() => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 48),
      );

  PhotoViewGalleryPageOptions _page(BuildContext context, int index) {
    final imageUrl = widget.imageUrls[index];
    final controller = _controllers.putIfAbsent(index, PhotoViewController.new);
    final scaleController = _scaleControllers.putIfAbsent(
      index,
      PhotoViewScaleStateController.new,
    );
    return PhotoViewGalleryPageOptions(
      imageProvider: CachedNetworkImageProvider(imageUrl),
      controller: controller,
      scaleStateController: scaleController,
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      heroAttributes: index == _currentIndex
          ? PhotoViewHeroAttributes(
              tag: index == widget.initialIndex && widget.heroTag != null
                  ? widget.heroTag!
                  : ImageViewer.heroTagFor(imageUrl, index),
            )
          : null,
      errorBuilder: (context, error, stackTrace) => _error(),
    );
  }
}
