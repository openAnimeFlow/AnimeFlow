import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/shared/widgets/collection_save_notice.dart';
import 'dart:ui';

import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/navigation/args/image_viewer_extra.dart';
import 'package:anime_flow/shared/navigation/args/video_resource_download_route_args.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/features/subject_episodes/application/subject_episodes_provider.dart';
import 'package:anime_flow/shared/models/bangumi/rating_item.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';
import 'package:anime_flow/shared/models/enums/collect_type.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/episodes_drawer.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_args_provider.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/collection_menu.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/shared/widgets/star.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

typedef _HeaderDetails = ({
  int id,
  String? airtime,
  String platform,
  int episodeCount,
  RatingItem rating,
  Collection collection,
});

@Dependencies([AnimeInfo, SubjectComments, animeInfoArgs])
class InfoHeadView extends StatelessWidget {
  final double statusBarHeight;
  final double toolbarHeight;
  final double contentHeight;
  final bool compact;
  final ValueChanged<int> onPlayEpisode;

  const InfoHeadView({
    super.key,
    required this.statusBarHeight,
    required this.toolbarHeight,
    required this.contentHeight,
    required this.compact,
    required this.onPlayEpisode,
  });

  static const double _compactWidth = 600;
  static const double _horizontalInset = 11;
  static const _titleStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const _titleGap = 6.0;
  static const _bottomInset = 6.0;
  static const _compactMinRowHeight = 200.0;

  static double compactContentHeight(
    BuildContext context,
    double safeWidth,
    String name,
  ) {
    final width =
        (safeWidth - 2 * _horizontalInset).clamp(0.0, double.infinity);
    final scaler = MediaQuery.textScalerOf(context);
    final title = TextPainter(
      text: TextSpan(
          text: name,
          style: DefaultTextStyle.of(context).style.merge(_titleStyle)),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: width);
    final titleHeight = title.height.ceilToDouble();
    title.dispose();
    final extraHeight = (scaler.scale(20) - 20).clamp(0.0, 32.0) * 4;
    return titleHeight +
        _titleGap +
        _compactMinRowHeight +
        extraHeight +
        _bottomInset;
  }

  static bool usesCompactLayout(double safeWidth) =>
      safeWidth - 2 * _horizontalInset < _compactWidth;
  @override
  Widget build(BuildContext context) {
    final layoutScale = switch ((compact, contentHeight)) {
      (false, >= 450) => 1.35,
      (false, >= 340) => 1.15,
      _ => 1.0,
    };
    final title = Consumer(builder: (context, ref, _) {
      final name = ref.watch(animeInfoArgsProvider.select((args) => args.name));
      return Text(
        name,
        style: _titleStyle.copyWith(fontSize: 20 * layoutScale),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    });
    final cover = _buildCover();
    // 仅布局约束变化时复用子树，状态、主题和语言变化仍正常触发重建。
    final details = Consumer(builder: (context, ref, child) {
      final subjectsInfo = ref.watch(animeInfoProvider.select(
        (state) => state.whenData(
          (subject) => (
            id: subject.id,
            airtime: subject.airtime?.date,
            platform: subject.platform.typeCN,
            episodeCount: subject.eps,
            rating: subject.rating,
            collection: subject.collection,
          ),
        ),
      ));
      return subjectsInfo.when(
        data: (data) => _dataView(
          context,
          ref: ref,
          subject: data,
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
            child: ClipRect(
              child: Opacity(
                opacity: 0.4,
                child: LayoutBuilder(
                  builder: (context, boxConstraints) {
                    return ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Colors.transparent],
                          stops: [0.72, 1],
                        ).createShader(bounds);
                      },
                      child: ImageFiltered(
                        imageFilter:
                            ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
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
        ),
        //数据层
        Positioned(
          top: statusBarHeight + toolbarHeight,
          left: _horizontalInset,
          right: _horizontalInset,
          bottom: compact ? _bottomInset : 20,
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: LayoutConstant.maxWidth),
              child: Padding(
                padding: EdgeInsets.only(
                  left: MediaQuery.paddingOf(context).left,
                  right: MediaQuery.paddingOf(context).right,
                ),
                child: SizedBox.expand(
                  child: LayoutBuilder(builder: (context, constraints) {
                    final row = LayoutBuilder(
                      builder: (context, rowConstraints) => _buildHeaderRow(
                        rowConstraints,
                        cover: cover,
                        details: compact
                            ? details
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: rowConstraints.maxHeight / 3,
                                    ),
                                    child: title,
                                  ),
                                  Expanded(child: details),
                                ],
                              ),
                        distribution: distribution,
                        layoutScale: layoutScale,
                        compact: compact,
                      ),
                    );
                    if (!compact) return row;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: _titleGap),
                        Expanded(child: row),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(
    BoxConstraints constraints, {
    required Widget cover,
    required Widget details,
    required Widget distribution,
    required double layoutScale,
    required bool compact,
  }) {
    final coverWidthLimit = constraints.maxWidth * (compact ? 0.45 : 0.4);
    final coverWidth =
        (constraints.maxHeight * 2 / 3).clamp(0.0, coverWidthLimit);
    final coverSpacing = (compact ? 10 : 5) * layoutScale;
    final detailsWidth = 320 * layoutScale;
    final chartWidth = 260 * layoutScale;
    final chartSpacing = 24 * layoutScale;
    final showDistribution = !compact &&
        contentHeight >= 260 &&
        constraints.maxHeight >= 180 &&
        constraints.maxWidth >=
            coverWidth +
                coverSpacing +
                detailsWidth +
                chartSpacing +
                chartWidth;

    return Row(
      spacing: coverSpacing,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: coverWidth,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: coverWidth,
              height: coverWidth * 1.5,
              child: cover,
            ),
          ),
        ),
        if (showDistribution) ...[
          SizedBox(width: detailsWidth, child: details),
          Padding(
            padding:
                EdgeInsetsDirectional.only(start: chartSpacing - coverSpacing),
            child: SizedBox(width: chartWidth, child: distribution),
          ),
        ] else
          Expanded(child: details),
      ],
    );
  }

  Widget _buildCover() {
    return Consumer(builder: (context, ref, _) {
      final image =
          ref.watch(animeInfoArgsProvider.select((args) => args.image));
      return GestureDetector(
        onTap: () => appNavigatorOf(context).openImagePreview<void>(
          ImageViewerRouteArgs(imageUrls: [image], heroTag: image),
        ),
        child: Hero(
          tag: image,
          child: AnimationNetworkImage(
            borderRadius: BorderRadius.circular(8),
            url: image,
            fit: BoxFit.cover,
          ),
        ),
      );
    });
  }

  Widget _skeletonView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = Color.lerp(
      baseColor,
      isDark ? colorScheme.onSurface : colorScheme.surface,
      isDark ? 0.08 : 0.65,
    )!;
    final boxDecoration = BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(8.0),
    );
    return _buildDetailsColumn(
      summary: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.only(top: 5),
              height: 20,
              width: 180,
              decoration: boxDecoration,
            );
          }),
        ),
      ),
      actions: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          height: 30,
          width: 100,
          decoration: boxDecoration,
        ),
      ),
    );
  }

  Widget _buildDetailsColumn({
    required Widget summary,
    required Widget actions,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(primary: false, child: summary),
            ),
            SizedBox(height: (constraints.maxHeight * 0.1).clamp(0.0, 6.0)),
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: constraints.maxHeight * 0.65),
              child: SingleChildScrollView(primary: false, child: actions),
            ),
          ],
        ),
      );
    });
  }

  Widget _dataView(
    BuildContext context, {
    required WidgetRef ref,
    required _HeaderDetails subject,
    required double layoutScale,
  }) {
    final name = ref.watch(animeInfoArgsProvider.select((e) => e.name));
    final l10n = AppLocalizations.of(context);
    final fontSize = 12 * layoutScale;
    const FontWeight fontWeight = FontWeight.w600;
    const amberAccent = Colors.amberAccent;
    final collectionTotal =
        subject.collection.data.values.fold(0, (sum, count) => sum + count);
    return _buildDetailsColumn(
      summary: Wrap(
        spacing: 5 * layoutScale,
        runSpacing: 5 * layoutScale,
        children: [
          Text(
            '${subject.airtime ?? l10n.noData}(${subject.platform})',
            style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(l10n.episodeCount(subject.episodeCount),
              style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer(builder: (context, ref, _) {
                final rate = ref.watch(animeInfoProvider.select(
                  (state) => state.value?.interest?.rate ?? 0,
                ));
                return rate > 0
                    ? Text(
                        l10n.yourRating(rate),
                        style: TextStyle(
                          fontSize: 14 * layoutScale,
                          fontWeight: fontWeight,
                          color: amberAccent,
                        ),
                      )
                    : const SizedBox.shrink();
              }),
              if (subject.rating.score > 0)
                Wrap(
                  spacing: 4 * layoutScale,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StarView(
                      score: subject.rating.score,
                      iconSize: 20 * layoutScale,
                    ),
                    Text(
                      subject.rating.score.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 14 * layoutScale,
                          fontWeight: fontWeight,
                          color: amberAccent),
                    ),
                    Text('#${subject.rating.rank}',
                        style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: fontWeight,
                            color: amberAccent))
                  ],
                ),
            ],
          ),
          Text(
            l10n.ratingCount(subject.rating.total),
            style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
          ),
          Text(l10n.collectionCount(collectionTotal),
              style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)),
          Text(l10n.watchingCount(subject.collection.data['3'] ?? 0),
              style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)),
          Text(l10n.droppedCount(subject.collection.data['5'] ?? 0),
              style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)),
        ],
      ),
      actions: Wrap(
        spacing: 8 * layoutScale,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth <
                80 * layoutScale +
                    MediaQuery.textScalerOf(context).scale(100 * layoutScale);
            return Consumer(
              builder: (context, ref, _) => _buildCollectionButton(
                context,
                ref,
                subjectId: subject.id,
                layoutScale: layoutScale,
                compact: compact,
              ),
            );
          }),
          Consumer(
            builder: (context, ref, child) {
              // 详情页存续期间保留剧集缓存。
              ref.watch(
                  subjectEpisodesProvider(subject.id).select((_) => null));
              return IconButton(
                style: IconButton.styleFrom(
                  padding: EdgeInsets.all(8 * layoutScale),
                  minimumSize: Size.square(48 * layoutScale),
                ),
                onPressed: () => EpisodesDrawerView.show(
                  context,
                  subjectId: subject.id,
                  onPlayEpisode: onPlayEpisode,
                  onDownloadEpisodes: (episodes) {
                    appNavigatorOf(context).openVideoResourceDownload<void>(
                      VideoResourceDownloadRouteArgs(
                        subjectName: name,
                        subjectCover: ref.read(animeInfoArgsProvider).image,
                        episodes: episodes,
                      ),
                    );
                  },
                  onEpisodeLongPress: (episode) async {
                    try {
                      await ref
                          .read(
                            subjectEpisodesProvider(subject.id).notifier,
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
    );
  }

  Widget _buildCollectionButton(
    BuildContext context,
    WidgetRef ref, {
    required int subjectId,
    required double layoutScale,
    required bool compact,
  }) {
    final l10n = AppLocalizations.of(context);
    final isLoggedIn = ref.watch(
      isLoggedInProvider.select((state) => state.value ?? false),
    );
    if (!isLoggedIn) {
      if (compact) {
        return IconButton.filled(
          tooltip: l10n.loginToCollect,
          onPressed: () => appNavigatorOf(context).goToUser(),
          icon: const Icon(Icons.login_rounded),
        );
      }
      return FilledButton.icon(
        onPressed: () => appNavigatorOf(context).goToUser(),
        style: OutlinedButton.styleFrom(
          minimumSize: Size(100 * layoutScale, 0),
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(12 * layoutScale),
          textStyle: TextStyle(fontSize: 12 * layoutScale),
        ),
        icon: Icon(Icons.login_rounded, size: 16 * layoutScale),
        label: Text(l10n.loginToCollect),
      );
    }
    final collectType = ref.watch(animeInfoProvider.select(
      (state) => collectTypeFromApiType(state.value?.interest?.type),
    ));
    @Dependencies([AnimeInfo, SubjectComments])
    Future<void> updateCollection(CollectType type) async {
      final session = ref.read(currentFlowTokenProvider).value?.sessionId;
      final previous = ref.read(animeInfoProvider).value?.interest;
      try {
        final result = await ref
            .read(animeInfoProvider.notifier)
            .updateCollectionType(type.value);
        if (!context.mounted ||
            ref.read(currentFlowTokenProvider).value?.sessionId != session ||
            ref.read(animeInfoProvider).asData?.value.id != subjectId) {
          return;
        }
        if (!type.isCollected &&
            previous != null &&
            (previous.rate > 0 || previous.comment.isNotEmpty)) {
          ref.read(subjectCommentsProvider.notifier).refresh();
        }
        showCollectionSaveNotice(context, result);
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
    }

    if (compact) {
      return CollectionMenu.icon(
        key: ValueKey(subjectId),
        collectType: collectType,
        iconColor: Theme.of(context).colorScheme.primary,
        onCollectTypeChanged: updateCollection,
      );
    }
    return CollectionMenu.labeled(
      key: ValueKey(subjectId),
      layoutScale: layoutScale,
      collectType: collectType,
      onCollectTypeChanged: updateCollection,
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
