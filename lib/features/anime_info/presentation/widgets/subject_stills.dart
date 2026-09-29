import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/router/model/image_viewer_extra.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/image_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 条目预览图横向列表。
class SubjectStillsView extends ConsumerWidget {
  const SubjectStillsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stills = ref.watch(subjectStillsProvider);
    return stills.when(
      data: (images) {
        if (images.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('预览图',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index];
                  final heroTag = ImageViewer.heroTagFor(image, index);
                  return Padding(
                    padding: EdgeInsets.only(
                        right: index == images.length - 1 ? 0 : 8),
                    child: GestureDetector(
                      onTap: () => ImagePreviewRoute.fromArgs(
                        ImageViewerRouteArgs(
                            imageUrls: images, initialIndex: index,heroTag: heroTag),
                      ).push(context),
                      child: Hero(
                        tag: heroTag,
                        child: AnimationNetworkImage(
                          url: image,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
