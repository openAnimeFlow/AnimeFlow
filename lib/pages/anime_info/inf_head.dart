import 'dart:ui';

import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/network/clients/flow_client.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/network/api/flow_api.dart';
import 'package:anime_flow/pages/anime_info/provider/anime_info_provider.dart';
import 'package:anime_flow/pages/anime_info/episodes_drawer.dart';
import 'package:anime_flow/providers/episodes/subject_episodes_provider.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/animation_network_image.dart';
import 'package:anime_flow/widget/collection/collection_button.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:anime_flow/widget/star.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

class InfoHeadView extends StatelessWidget {
  final double statusBarHeight;
  final double contentHeight;

  const InfoHeadView({
    super.key,
    required this.statusBarHeight,
    required this.contentHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
                      child: Consumer(
                        builder: (context, ref, _) {
                          final image = ref.watch(
                            animeInfoArgsProvider.select((e) => e.image),
                          );
                          return AnimationNetworkImage(
                            url: image,
                            width: boxConstraints.maxWidth,
                            height: boxConstraints.maxHeight,
                            fit: BoxFit.cover,
                          );
                        },
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
                  const BoxConstraints(maxWidth: LayoutConstant.maxWidth),
              child: SizedBox(
                height: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(
                      left: MediaQuery.of(context).padding.left),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        //封面
                        Flexible(
                          flex: 2,
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: Container(
                              margin: const EdgeInsets.only(left: 6),
                              child: Consumer(
                                builder: (context, ref, _) {
                                  final image = ref.watch(
                                    animeInfoArgsProvider
                                        .select((e) => e.image),
                                  );
                                  return Hero(
                                    tag: image,
                                    child: AnimationNetworkImage(
                                      preview: true,
                                      useExternalHero: true,
                                      borderRadius: BorderRadius.circular(8),
                                      url: image,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          flex: 3,
                          child: Consumer(builder: (context, ref, child) {
                            final subjectsInfo = ref.watch(animeInfoProvider);
                            return subjectsInfo.when(
                                data: (data) => _dataView(
                                      context,
                                      ref: ref,
                                      subjectItem: data,
                                    ),
                                error: (error, stackTrace) =>
                                    const SizedBox.shrink(),
                                loading: () => _skeletonView(context));
                          }),
                        )
                      ]),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _skeletonView(BuildContext context) {
    final isDark = SystemUtil.isDarkTheme(context);
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final containerColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).colorScheme.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 30,
            width: 250,
            decoration: BoxDecoration(
              color: containerColor,
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
                  color: containerColor,
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
              color: containerColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dataView(
    BuildContext context, {
    required WidgetRef ref,
    required SubjectsInfoItem subjectItem,
  }) {
    final name = ref.watch(animeInfoArgsProvider.select((e) => e.name));
    const double fontSize = 12;
    const FontWeight fontWeight = FontWeight.w600;
    const amberAccent = Colors.amberAccent;
    final collectionTotal =
        subjectItem.collection.data.values.reduce((a, b) => a + b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Wrap(
          spacing: 5,
          runSpacing: 5,
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
        Row(
          spacing: 8,
          children: [
            CollectionButton(
              collectType: collectTypeFromApiType(subjectItem.interest?.type),
              onCollectTypeChanged: (type) async {
                try {
                  await FlowApi.updateCollectionService(
                    subjectItem.id,
                    type: type.value,
                    subjectType: subjectItem.type,
                  );
                  if (context.mounted) {
                    NotificationToast.show(
                      '收藏更新',
                      '已${type.label}',
                      maxWidth: 500,
                    );
                  }
                  ref.invalidate(currentUserInfoProvider);
                } on AnimeFlowApiException catch (e) {
                  if (context.mounted) {
                    NotificationToast.show(
                      '收藏更新失败',
                      e.message,
                      maxWidth: 500,
                    );
                  }
                  rethrow;
                }
              },
            ),
            Consumer(
              builder: (context, ref, child) {
                final image =
                    ref.watch(animeInfoArgsProvider.select((e) => e.image));
                // Keep episodes cached while the anime info page is alive.
                ref.watch(subjectEpisodesProvider(subjectItem.id));
                return IconButton(
                  onPressed: () => EpisodesDrawerView.show(
                    context,
                    subjectItem: subjectItem,
                    subjectName: name,
                    subjectImage: image,
                    onEpisodeLongPress: (episodeId) async {
                      try {
                        await ref
                            .read(
                              subjectEpisodesProvider(subjectItem.id).notifier,
                            )
                            .updateEpisodeWatched(episodeId: episodeId);
                        if (!context.mounted) return;
                        NotificationToast.show('提示', '已更新观看进度');
                      } on AnimeFlowApiException catch (e) {
                        if (!context.mounted) return;
                        NotificationToast.show('更新失败', e.message);
                      } catch (e) {
                        if (!context.mounted) return;
                        NotificationToast.show('更新失败', e.toString());
                      }
                    },
                  ),
                  icon:
                      const Icon(Icons.format_list_bulleted_rounded, size: 25),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
