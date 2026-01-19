import 'dart:ui';
import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/stores/anime_info_store.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/collection/collection_button.dart';
import 'package:anime_flow/widget/star.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart'
    show SubjectBasicData;

class InfoHeadView extends StatelessWidget {
  final SubjectBasicData subjectBasicData;
  final double statusBarHeight;
  final double contentHeight;
  final String storeTag;

  const InfoHeadView({
    super.key,
    required this.statusBarHeight,
    required this.contentHeight,
    required this.subjectBasicData,
    required this.storeTag,
  });

  @override
  Widget build(BuildContext context) {
    final animeInfoStore = Get.find<AnimeInfoStore>(tag: storeTag);
    final themeColor = Theme.of(context).colorScheme.primary;
    return Stack(
      children: [
        // 背景层
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.4,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  return ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Colors.transparent],
                          stops: [0.8, 1],
                        ).createShader(bounds);
                      },
                      child: AnimationNetworkImage(
                        url: subjectBasicData.image,
                        width: boxConstraints.maxWidth,
                        height: boxConstraints.maxHeight,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        //数据层
        Positioned(
          top: statusBarHeight + kToolbarHeight,
          left: 5,
          right: 5,
          bottom: 5,
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: PlayLayoutConstant.maxWidth),
              child: SizedBox(
                height: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(
                      left: MediaQuery.of(context).padding.left),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        //封面
                        Flexible(
                            flex: 2,
                            child: AspectRatio(
                                aspectRatio: 2 / 3,
                                child: Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  child: AnimationNetworkImage(
                                    preview: true,
                                    borderRadius: BorderRadius.circular(8),
                                    url: subjectBasicData.image,
                                    fit: BoxFit.cover,
                                  ),
                                ))),
                        const SizedBox(width: 5),
                        //信息
                        Flexible(
                          flex: 3, // 文本占3份
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Obx(
                                  () => animeInfoStore.animeInfo.value == null
                                      ? Expanded(child: _skeletonView())
                                      : Expanded(
                                          child: _dataView(context,
                                              themeColor: themeColor),
                                        ),
                                )
                              ]),
                        ),
                      ]),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  ///骨架屏
  Widget _skeletonView() {
    const baseColor = Colors.white38;
    const highlightColor = Colors.white24;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 30,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(4, (index) {
              return Container(
                margin: const EdgeInsets.only(top: 5),
                height: 20,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              );
            }),
          ),
        ),
        const Spacer(),
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 30,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ],
    );
  }

  ///数据视图
  Widget _dataView(BuildContext context, {required Color themeColor}) {
    final animeInfoStore = Get.find<AnimeInfoStore>(tag: storeTag);
    const double fontSize = 12;
    const FontWeight fontWeight = FontWeight.w600;
    const amberAccent = Colors.amberAccent;
    return Obx(() {
      final subjectItem = animeInfoStore.animeInfo.value!;
      final collectionTotal =
          subjectItem.collection.data.values.reduce((a, b) => a + b);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subjectBasicData.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Wrap(
            spacing: 5, // 子组件之间的水平间距
            runSpacing: 5, // 行之间的垂直间距
            children: [
              Text(
                '${subjectItem.airtime.date}(${subjectItem.platform.typeCN})',
                style:
                    const TextStyle(fontSize: fontSize, fontWeight: fontWeight),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('全${subjectItem.eps}话',
                  style: const TextStyle(
                      fontSize: fontSize, fontWeight: fontWeight)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subjectItem.interest != null &&
                      subjectItem.interest!.rate > 0)
                    Text(
                      '你的评分:${subjectItem.interest!.rate}',
                      style: const TextStyle(
                          fontWeight: fontWeight, color: amberAccent),
                    ),
                  Row(children: [
                    if (subjectItem.rating.score > 0) ...[
                      StarView(score: subjectItem.rating.score, iconSize: 20),
                      Text(
                        subjectItem.rating.score.toStringAsFixed(1),
                        style: const TextStyle(
                            fontWeight: fontWeight, color: amberAccent),
                      ),
                      const SizedBox(width: 5),
                      Text('#${subjectItem.rating.rank}',
                          style: const TextStyle(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: amberAccent))
                    ],
                  ]),
                ],
              ),
              Text(
                '(${subjectItem.rating.total})人评分',
                style:
                    const TextStyle(fontSize: fontSize, fontWeight: fontWeight),
              ),
              Text('$collectionTotal收藏/',
                  style: const TextStyle(
                      fontSize: fontSize, fontWeight: fontWeight)),
              Text('${subjectItem.collection.data['3']}再看/',
                  style: const TextStyle(
                      fontSize: fontSize, fontWeight: fontWeight)),
              Text('${subjectItem.collection.data['5']}抛弃',
                  style: const TextStyle(
                      fontSize: fontSize, fontWeight: fontWeight)),
            ],
          ),
          const Spacer(),
          CollectionButton(
            subjectId: subjectBasicData.id,
            subject: subjectItem,
          ),
        ],
      );
    });
  }
}
