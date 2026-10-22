import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/shared/widgets/collection_save_notice.dart';
import 'dart:ui';

import 'package:anime_flow/app/router/app_router.dart';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/model/image_viewer_extra.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/features/play/presentation/providers/subject_episodes_provider.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/episodes_drawer.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/collection_button.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/shared/widgets/star.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

class InfoHeadView extends StatelessWidget {
  final double statusBarHeight;
  final double contentHeight;
  final ValueChanged<int> onPlayEpisode;

  const InfoHeadView({
    super.key,
    required this.statusBarHeight,
    required this.contentHeight,
    required this.onPlayEpisode,
  });

  @override
  Widget build(BuildContext context) {
    final layoutScale = switch (contentHeight) {
      >= 450 => 1.35,
      >= 340 => 1.15,
      _ => 1.0,
    };
    // 仅布局约束变化时复用子树，状态、主题和语言变化仍正常触发重建。
    final details = Consumer(builder: (context, ref, child) {
      final subjectsInfo = ref.watch(animeInfoProvider);
      return subjectsInfo.when(
        data: (data) => _dataView(
          context,
          ref: ref,
          subjectItem: data,
          layoutScale: layoutScale,
        ),
        error: (error, stackTrace) => const SizedBox.shrink(),
        loading: () => _skeletonView(context),
      );
    });
    final distribution = RepaintBoundary(
      child: Consumer(builder: (context, ref, _) {
        final rating = ref.watch(
          animeInfoProvider.select((value) => value.value?.rating),
        );
        return rating == null
            ? const SizedBox.shrink()
            : _ratingDistribution(
                context,
                count: rating.count,
                layoutScale: layoutScale,
              );
      }),
    );
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
                  padding:
                      EdgeInsets.only(left: MediaQuery.paddingOf(context).left),
                  child: LayoutBuilder(builder: (context, constraints) {
                    final coverWidth = (constraints.maxHeight * 2 / 3)
                        .clamp(0.0, constraints.maxWidth * 0.4);
                    final detailsWidth = 320 * layoutScale;
                    final chartWidth = 260 * layoutScale;
                    final chartSpacing = 24 * layoutScale;
                    final coverSpacing = 5 * layoutScale;
                    final showDistribution = contentHeight >= 260 &&
                        constraints.maxHeight >= 180 &&
                        constraints.maxWidth >=
                            coverWidth +
                                coverSpacing +
                                detailsWidth +
                                chartSpacing +
                                chartWidth;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        //封面
                        SizedBox(
                          width: coverWidth,
                          height: constraints.maxHeight,
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
                                  return GestureDetector(
                                    onTap: () => ImagePreviewRoute.fromArgs(
                                      ImageViewerRouteArgs(
                                        imageUrls: [image],
                                        heroTag: image,
                                      ),
                                    ).push(context),
                                    child: Hero(
                                      tag: image,
                                      child: AnimationNetworkImage(
                                        borderRadius: BorderRadius.circular(8),
                                        url: image,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: coverSpacing),
                        SizedBox(
                          width: showDistribution
                              ? detailsWidth
                              : (constraints.maxWidth -
                                      coverWidth -
                                      coverSpacing)
                                  .clamp(0.0, double.infinity),
                          height: constraints.maxHeight,
                          child: details,
                        ),
                        if (showDistribution) ...[
                          SizedBox(width: chartSpacing),
                          SizedBox(
                            width: chartWidth,
                            height: constraints.maxHeight,
                            child: distribution,
                          ),
                        ],
                      ],
                    );
                  }),
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
    required double layoutScale,
  }) {
    final name = ref.watch(animeInfoArgsProvider.select((e) => e.name));
    final l10n = AppLocalizations.of(context);
    final fontSize = 12 * layoutScale;
    const FontWeight fontWeight = FontWeight.w600;
    const amberAccent = Colors.amberAccent;
    final isLoggedIn = ref.watch(isLoggedInProvider).value ?? false;
    Widget buildCollectionButton(
      BuildContext context,
      String label,
      IconData icon,
      VoidCallback onPressed,
    ) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(100 * layoutScale, 0),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 12 * layoutScale,
            vertical: 12 * layoutScale,
          ),
          textStyle: TextStyle(fontSize: fontSize),
        ),
        icon: Icon(icon, size: 16 * layoutScale),
        label: Text(label),
      );
    }

    final collectionTotal =
        subjectItem.collection.data.values.reduce((a, b) => a + b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 20 * layoutScale,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Wrap(
          spacing: 5 * layoutScale,
          runSpacing: 5 * layoutScale,
          children: [
            Text(
              '${subjectItem.airtime?.date ?? l10n.noData}(${subjectItem.platform.typeCN})',
              style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(l10n.episodeCount(subjectItem.eps),
                style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subjectItem.interest != null &&
                    subjectItem.interest!.rate > 0)
                  Text(
                    l10n.yourRating(subjectItem.interest!.rate),
                    style: TextStyle(
                        fontSize: 14 * layoutScale,
                        fontWeight: fontWeight,
                        color: amberAccent),
                  ),
                Row(children: [
                  if (subjectItem.rating.score > 0) ...[
                    StarView(
                      score: subjectItem.rating.score,
                      iconSize: 20 * layoutScale,
                    ),
                    Text(
                      subjectItem.rating.score.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 14 * layoutScale,
                          fontWeight: fontWeight,
                          color: amberAccent),
                    ),
                    SizedBox(width: 5 * layoutScale),
                    Text('#${subjectItem.rating.rank}',
                        style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: fontWeight,
                            color: amberAccent))
                  ],
                ]),
              ],
            ),
            Text(
              l10n.ratingCount(subjectItem.rating.total),
              style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
            ),
            Text(l10n.collectionCount(collectionTotal),
                style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)),
            Text(l10n.watchingCount(subjectItem.collection.data['3'] ?? 0),
                style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)),
            Text(l10n.droppedCount(subjectItem.collection.data['5'] ?? 0),
                style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)),
          ],
        ),
        const Spacer(),
        Row(
          spacing: 8 * layoutScale,
          children: [
            if (!isLoggedIn)
              buildCollectionButton(
                context,
                l10n.loginToCollect,
                Icons.login_rounded,
                () => const UserRoute().go(context),
              )
            else
              CollectionButton(
                buttonBuilder: (context, label, icon, onPressed) =>
                    buildCollectionButton(context, label, icon, onPressed),
                collectType: collectTypeFromApiType(subjectItem.interest?.type),
                offset: const Offset(0, 50),
                onCollectTypeChanged: (type) async {
                  try {
                    final result = await ref
                        .read(animeInfoProvider.notifier)
                        .updateCollectionType(type.value);
                    if (context.mounted) {
                      showCollectionSaveNotice(context, result);
                    }
                  } on AnimeFlowApiException catch (e) {
                    if (context.mounted) {
                      NotificationToast.show(
                        e.message,
                        title: '收藏更新失败',
                        maxWidth: 500,
                      );
                    }
                    rethrow;
                  }
                },
              ),
            Consumer(
              builder: (context, ref, child) {
                // 详情页存续期间保留剧集缓存。
                ref.watch(subjectEpisodesProvider(subjectItem.id));
                return IconButton(
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.all(8 * layoutScale),
                    minimumSize: Size.square(48 * layoutScale),
                  ),
                  onPressed: () => EpisodesDrawerView.show(
                    context,
                    subjectId: subjectItem.id,
                    onPlayEpisode: onPlayEpisode,
                    onEpisodeLongPress: (episode) async {
                      try {
                        await ref
                            .read(
                              subjectEpisodesProvider(subjectItem.id).notifier,
                            )
                            .updateEpisodeWatched(
                              episodeId: episode.id,
                              watched: episode.watched != true,
                            );
                        if (!context.mounted) return;
                        NotificationToast.show('已更新观看进度', title: '提示');
                      } on AnimeFlowApiException catch (e) {
                        if (!context.mounted) return;
                        NotificationToast.show(e.message, title: '更新失败');
                      } catch (e) {
                        if (!context.mounted) return;
                        NotificationToast.show(e.toString(), title: '更新失败');
                      }
                    },
                  ),
                  icon: Icon(Icons.format_list_bulleted_rounded,
                      size: 25 * layoutScale),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _ratingDistribution(
    BuildContext context, {
    required List<int> count,
    required double layoutScale,
  }) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final votes = List.generate(
      10,
      (index) => index < count.length && count[index] > 0 ? count[index] : 0,
    );
    final maxVotes = votes.reduce((a, b) => a > b ? a : b);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10 * layoutScale,
          fontWeight: FontWeight.w500,
          color: colors.onSurfaceVariant,
        );
    return Column(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(10, (index) {
                final value = votes[index];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3 * layoutScale),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final maxBarHeight =
                          (constraints.maxHeight - 24 * layoutScale)
                              .clamp(0.0, double.infinity);
                      final height =
                          maxVotes == 0 ? 0.0 : maxBarHeight * value / maxVotes;
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Tooltip(
                          richMessage: TextSpan(
                            children: [
                              TextSpan(
                                text: '${index + 1} ',
                                semanticsLabel: '${index + 1}/10 ',
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: ExcludeSemantics(
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 14 * layoutScale,
                                    color: Theme.of(context)
                                            .tooltipTheme
                                            .textStyle
                                            ?.color ??
                                        colors.onInverseSurface,
                                  ),
                                ),
                              ),
                              TextSpan(text: ' · ${l10n.ratingCount(value)}'),
                            ],
                          ),
                          preferBelow: false,
                          // 锚点取实际柱体和票数标签的中心，向上偏移至标签顶部。
                          verticalOffset:
                              (height + 24 * layoutScale) / 2 + 8 * layoutScale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 18 * layoutScale,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('$value', style: labelStyle),
                                ),
                              ),
                              SizedBox(height: 6 * layoutScale),
                              Container(
                                height: height,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(
                                    alpha: value == maxVotes ? 1 : 0.7,
                                  ),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(3 * layoutScale),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
        SizedBox(height: 6 * layoutScale),
        SizedBox(
          height: 18 * layoutScale,
          child: Row(
            children: List.generate(
              10,
              (index) => Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${index + 1}', style: labelStyle),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
