import 'dart:math';
import 'dart:ui';
import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/anime_detail/episodes_dialog.dart';
import 'package:anime_flow/widget/star.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/models/item/bangumi/subjects_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart'
    show SubjectBasicData;

class InfoHeadView extends StatelessWidget {
  final SubjectBasicData subjectBasicData;
  final SubjectsItem? subjectItem;
  final Future<EpisodesItem> episodesItem;
  final double statusBarHeight;
  final double contentHeight;

  const InfoHeadView({
    super.key,
    required this.statusBarHeight,
    required this.contentHeight,
    required this.episodesItem,
    required this.subjectItem,
    required this.subjectBasicData,
  });

  @override
  Widget build(BuildContext context) {
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
              constraints: const BoxConstraints(
                  maxWidth: PlayLayoutConstant.infoMaxWidth),
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
                              children: [
                                subjectItem == null
                                    ? _skeletonView()
                                    : _dataView(
                                        subjectItem: subjectItem!,
                                        themeColor: themeColor),
                                const Spacer(),
                                Row(children: [
                                  IconButton(
                                    onPressed: () {
                                      episodesDialog(context, episodesItem);
                                    },
                                    icon: const Icon(
                                      Icons.grid_view_rounded,
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 150,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Get.toNamed(RouteName.play, arguments: {
                                          "subjectBasicData": subjectBasicData,
                                          "episodes": episodesItem
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: themeColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.play_circle_outline,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        "播放",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ]),
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
              children: List.generate(5, (index) {
                final double width = Random().nextInt(200).toDouble();
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
            ))
      ],
    );
  }

  ///数据视图
  Widget _dataView(
      {required SubjectsItem subjectItem, required Color themeColor}) {
    final collectionTotal =
        subjectItem.collection.data.values.reduce((a, b) => a + b);
    const double fontSize = 12;
    const FontWeight fontWeight = FontWeight.w600;
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
            Row(children: [
              StarView(score: subjectItem.rating.score, iconSize: 20),
              Text(
                subjectItem.rating.score.toStringAsFixed(1),
                style: TextStyle(fontWeight: fontWeight, color: themeColor),
              ),
              const SizedBox(width: 5),
              Text('#${subjectItem.rating.rank}',
                  style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: fontWeight,
                      color: themeColor))
            ]),
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
        )
      ],
    );
  }
}
