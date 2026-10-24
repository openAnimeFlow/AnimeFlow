import 'dart:typed_data';

class ImageViewerRouteArgs {
  ImageViewerRouteArgs({
    List<String> imageUrls = const [],
    List<Uint8List> imageBytes = const [],
    this.initialIndex = 0,
    this.heroTag,
  })  : imageUrls = List.unmodifiable(imageUrls),
        imageBytes = List.unmodifiable(imageBytes);

  /// 从播放器截图等内存数据打开预览，无需网络地址。
  ImageViewerRouteArgs.bytes(
    Uint8List bytes, {
    this.initialIndex = 0,
    this.heroTag,
  })  : imageUrls = const [],
        imageBytes = List.unmodifiable([bytes]);

  final List<String> imageUrls;

  /// 内存中的图片数据，优先于 [imageUrls]。
  final List<Uint8List> imageBytes;
  final int initialIndex;
  final Object? heroTag;
}
