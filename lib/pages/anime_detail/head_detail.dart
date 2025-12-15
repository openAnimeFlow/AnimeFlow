import 'dart:ui';
import 'package:anime_flow/widget/anime_detail/episodes_dialog.dart';
import 'package:anime_flow/widget/anime_detail/star.dart';
import 'package:anime_flow/widget/image/animation_network_image.dart';
import 'package:anime_flow/models/item/episodes_item.dart';
import 'package:anime_flow/models/item/hot_item.dart';
import 'package:anime_flow/models/item/subjects_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HeadDetailView extends StatelessWidget {
  final Subject subject;
  final SubjectsItem? subjectItem;
  final Future<EpisodesItem> episodesItem;
  final double statusBarHeight;
  final double contentHeight;

  const HeadDetailView({
    super.key,
    required this.statusBarHeight,
    required this.contentHeight,
    required this.episodesItem,
    required this.subject,
    required this.subjectItem,
  });

  @override
  Widget build(BuildContext context) {
    final Color themeColor = Theme.of(context).colorScheme.primary;

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
                        url: subject.images.large,
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
          child: SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //封面
                Flexible(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: AnimationNetworkImage(
                        url: subject.images.large,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                //信息
                Flexible(
                  flex: 3, // 文本占3份
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.nameCN ?? subject.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      //TODO 添加骨架屏
                      Card(
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            subjectItem?.airtime.date ?? '',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          StarView(score: subjectItem?.rating.score ?? 0,iconSize: 20),
                          const SizedBox(width: 5),
                          Text(
                            subjectItem?.rating.score.toStringAsFixed(1) ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: themeColor),
                          )
                        ],
                      ),

                      const Spacer(),
                      Row(
                        children: [
                          IconButton(
                              onPressed: () {
                                episodesDialog(context, episodesItem);
                              },
                              icon: const Icon(
                                Icons.grid_view_rounded,
                                size: 28,
                              )),
                          OutlinedButton.icon(
                            onPressed: () {
                              Get.toNamed("/play", arguments: {
                                "subject": subject,
                                "episodes": episodesItem
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: themeColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
