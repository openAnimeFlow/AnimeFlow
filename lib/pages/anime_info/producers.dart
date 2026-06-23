import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/pages/anime_info/provider/anime_info_provider.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 番剧制作人信息
class ProducersView extends StatelessWidget {
  const ProducersView({super.key});

  @override
  Widget build(BuildContext context) {
    final windowsWidth = MediaQuery.of(context).size.width;
    return Consumer(builder: (context, ref, child) {
      final asyncProducers = ref.watch(subjectProducersProvider);
      return asyncProducers.when(
          data: (producers) {
            if (producers.total > 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '制作人',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: windowsWidth > 600 ? 180 : 100,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        scrollbars: false,
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                      itemCount: producers.data.length,
                      itemBuilder: (BuildContext context, int index) {
                        final staffItem = producers.data[index];
                        return SizedBox(
                          width: windowsWidth > 600 ? 90 : 60,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 3,
                            children: [
                              Container(
                                //获取最后一项
                                margin: EdgeInsets.only(
                                    right: index == producers.data.length - 1
                                        ? 0
                                        : 8),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: AnimationNetworkImage(
                                    borderRadius: BorderRadius.circular(10),
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    url: staffItem.staff.images?.medium ??
                                        Constants.notImage,
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
                                    fontSize: 12,
                                    color: Theme.of(context).disabledColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  ),
                ],
              );
            } else {
              return const SizedBox.shrink();
            }
          },
          error: (error, stackTrace) {
            LiggLogger().e('获取制作人信息失败', error: error, stackTrace: stackTrace);
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink());
    });
  }
}
