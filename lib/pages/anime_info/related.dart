import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/related_subjects_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///相关条目
class RelatedView extends StatefulWidget {
  final String title;
  final int subjectId;

  const RelatedView({super.key, required this.subjectId, required this.title});

  @override
  State<RelatedView> createState() => _RelatedViewState();
}

class _RelatedViewState extends State<RelatedView> {
  SubjectRelationItem? subjectRelation;

  @override
  void initState() {
    super.initState();
    _getSubjectRelation();
  }

  void _getSubjectRelation() async {
    final subjectRelation = await BgmRequest.relatedSubjectsService(
        widget.subjectId,
        limit: 20,
        offset: 0);
    setState(() {
      this.subjectRelation = subjectRelation;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (subjectRelation == null) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }
    if (subjectRelation!.data.isEmpty) {
      return const SizedBox.shrink();
    } else {
      final relation = subjectRelation!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              relation.total > 20
                  ? TextButton(onPressed: () {}, child: const Text('查看全部'))
                  : const SizedBox.shrink(),
            ],
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: relation.data.length,
              cacheExtent: 200, // 缓存范围，优化滚动性能
              addAutomaticKeepAlives: false, // 不自动保持item状态，节省内存
              addRepaintBoundaries: true, // 添加重绘边界，优化性能
              itemBuilder: (context, index) {
                final item = relation.data[index];
                final subjectBasicData = SubjectBasicData(
                  id: item.subject.id,
                  name: item.subject.nameCN.isEmpty
                      ? item.subject.name
                      : item.subject.nameCN,
                  image: item.subject.images.large,
                );
                return Container(
                    width: 100,
                    margin: const EdgeInsets.all(5),
                    child: InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed(RouteName.animeInfo,
                              arguments: subjectBasicData);
                        },
                        child: Column(
                          children: [
                            AnimationNetworkImage(
                                borderRadius: BorderRadius.circular(10),
                                url: item.subject.images.large),
                            Text(
                              item.subject.nameCN.isEmpty
                                  ? item.subject.name
                                  : item.subject.nameCN,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          ],
                        )));
              },
            ),
          )
        ],
      );
    }
  }
}
