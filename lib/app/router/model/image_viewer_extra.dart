class ImageViewerRouteArgs {
  ImageViewerRouteArgs({
    required List<String> imageUrls,
    this.initialIndex = 0,
    this.heroTag,
  }) : imageUrls = List.unmodifiable(imageUrls);

  final List<String> imageUrls;
  final int initialIndex;
  final Object? heroTag;
}