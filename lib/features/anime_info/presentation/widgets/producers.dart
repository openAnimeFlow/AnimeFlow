import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/debounced_image_width.dart';
import 'package:material_ui/material_ui.dart';
import 'package:anime_flow/shared/models/bangumi/producers_item.dart';

class ProducersView extends StatelessWidget {
  const ProducersView({super.key, required this.producers});

  final List<StaffData> producers;

  @override
  Widget build(BuildContext context) {
    final windowsWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = windowsWidth > 600 ? 90.0 : 60.0;
    return SizedBox(
      height: windowsWidth > 600 ? 180 : 100,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: producers.length,
          itemBuilder: (BuildContext context, int index) {
            final staffItem = producers[index];
            final imageInset = index == producers.length - 1 ? 0.0 : 8.0;
            return SizedBox(
              width: cardWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Container(
                    //获取最后一项
                    margin: EdgeInsets.only(right: imageInset),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: DebouncedImageWidth(
                        width: cardWidth - imageInset,
                        builder: (context, cacheWidth) => AnimationNetworkImage(
                          memCacheWidth: cacheWidth,
                          gaplessResize: true,
                          borderRadius: BorderRadius.circular(10),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          url: staffItem.staff.images?.medium ??
                              Constants.notImage,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    staffItem.staff.nameCN ?? staffItem.staff.name,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    staffItem.positions.isNotEmpty
                        ? staffItem.positions[0].type.cn
                        : '',
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).disabledColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
