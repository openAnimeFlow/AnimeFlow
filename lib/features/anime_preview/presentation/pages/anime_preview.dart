import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/router/model/image_viewer_extra.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/image_preview.dart';
import 'package:flutter/material.dart';

class AnimePreviewPage extends StatelessWidget {
  final List<String> images;
  final String? title;

  const AnimePreviewPage({super.key, required this.images, this.title});

  @override
  Widget build(BuildContext context) {
    const maxContentWidth = 2000.0;
    const itemWidth = 320.0;
    const innerPadding = 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${title ?? '预览图'} (${images.length})'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sidePadding = constraints.maxWidth > maxContentWidth
              ? (constraints.maxWidth - maxContentWidth) / 2
              : 0.0;

          final contentWidth = constraints.maxWidth - sidePadding * 2;
          final gridWidth = contentWidth - innerPadding * 2;

          final crossAxisCount = (gridWidth / itemWidth).floor().clamp(2, 7);
          return GridView.builder(
              padding: EdgeInsets.fromLTRB(sidePadding + innerPadding,
                  innerPadding, sidePadding + innerPadding, innerPadding),
              itemCount: images.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 16 / 9),
              itemBuilder: (context, index) {
                final image = images[index];
                final heroTag = ImageViewer.heroTagFor(image, index);
                return GestureDetector(
                  onTap: () => ImagePreviewRoute.fromArgs(ImageViewerRouteArgs(
                          imageUrls: images,
                          initialIndex: index,
                          heroTag: heroTag))
                      .push(context),
                  child: Hero(
                    tag: heroTag,
                    child: AnimationNetworkImage(
                      url: image,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              });
        },
      ),
    );
  }
}
