import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/pages/anime_info/provider/anime_info_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///相关条目
class RelatedView extends StatelessWidget {
  final int subjectId;

  const RelatedView({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final asyncRelation = ref.watch(subjectRelatedProvider(subjectId));
      return asyncRelation.when(
          data: (relation) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (relation.data.isNotEmpty) ...[
                    const Text(
                      '关联条目',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: relation.data.length,
                        itemBuilder: (context, index) {
                          final item = relation.data[index];
                          final subjectBasicData = SubjectBasicData(
                            id: item.subject.id,
                            name: item.subject.nameCN.isEmpty ? item.subject.name : item.subject.nameCN,
                            image: item.subject.images.large,
                          );
                          return Container(
                            width: 100,
                            margin: EdgeInsets.only(
                                right:
                                    index == relation.data.length - 1 ? 0 : 5),
                            child: InkWell(
                              onTap: () {
                                AnimeInfoRoute.fromData(subjectBasicData)
                                    .push(context);
                              },
                              child: Column(
                                children: [
                                  AnimationNetworkImage(
                                      borderRadius: BorderRadius.circular(10),
                                      url: item.subject.images.large),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: Text(
                                      item.subject.nameCN.isEmpty ? item.subject.name : item.subject.nameCN,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ]
                ],
              ),
          error: (error, stackTrace) {
            LiggLogger().e(error, stackTrace: stackTrace);
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink());
    });
  }
}
