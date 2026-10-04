import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/router/model/image_viewer_extra.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/image_preview.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 条目预览图横向列表。
class SubjectStillsView extends ConsumerWidget {
  const SubjectStillsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stills = ref.watch(subjectStillsProvider);
    final subjectName = ref.watch(animeInfoArgsProvider.select((s) => s.name));
    return stills.when(
      data: (images) {
        if (images.isEmpty) return const SizedBox.shrink();
        final imageFilter = images.take(10).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('预览图',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (images.length > 10)
                  IconButton(
                      onPressed: () {
                        AnimePreviewPageRoute(
                                images: images, title: subjectName)
                            .push(context);
                      },
                      icon: const Icon(Icons.keyboard_double_arrow_right_outlined))
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imageFilter.length,
                itemBuilder: (context, index) {
                  final image = imageFilter[index];
                  final heroTag = ImageViewer.heroTagFor(image, index);
                  return Padding(
                    padding: EdgeInsets.only(
                        right: index == imageFilter.length - 1 ? 0 : 8),
                    child: GestureDetector(
                      onTap: () => ImagePreviewRoute.fromArgs(
                        ImageViewerRouteArgs(
                            imageUrls: imageFilter,
                            initialIndex: index,
                            heroTag: heroTag),
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
