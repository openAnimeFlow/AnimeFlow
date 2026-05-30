import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/pages/anime_info/provider/anime_info_provider.dart';
import 'package:anime_flow/pages/anime_info/characters.dart';
import 'package:anime_flow/pages/anime_info/info_comment.dart';
import 'package:anime_flow/pages/anime_info/details.dart';
import 'package:anime_flow/pages/anime_info/producers.dart';
import 'package:anime_flow/pages/anime_info/related.dart';
import 'package:anime_flow/pages/anime_info/tags.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

/// 条目详情信息展示ui
class InfoSynopsisView extends StatelessWidget {
  final int subjectId;

  final ValueChanged<bool>? onScrollChanged;

  const InfoSynopsisView({
    super.key,
    required this.subjectId,
    this.onScrollChanged,
  });

  List<Widget> _sliversForSubjectsInfo(
    BuildContext context,
    SubjectsInfoItem subjectsInfo, {
    required int subjectId,
    required String title,
    required double fontSizeTitle,
    required FontWeight fontWeightTitle,
    required FontWeight fontWeight,
  }) {
    return [
      SliverToBoxAdapter(
        child: _buildContainer(
          context,
          ExpandableText(
            title: title,
            fontSizeTitle: fontSizeTitle,
            fontWeightTitle: fontWeightTitle,
            text: subjectsInfo.summary,
            fontWeight: fontWeight,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: _buildContainer(
          context,
          topPadding: 25,
          TagView(
            title: '标签',
            fontSizeTitle: fontSizeTitle,
            fontWeightTitle: fontWeightTitle,
            tags: subjectsInfo.tags,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            numbersSize: 10,
            numbersWeight: FontWeight.w600,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: _buildContainer(
          context,
          DetailsView(
            title: '详情',
            subject: subjectsInfo,
            textSize: 13,
            textFontWeight: FontWeight.w600,
          ),
          topPadding: 25,
        ),
      ),
      SliverToBoxAdapter(
        child: _buildContainer(
          context,
          CharactersView(subjectsId: subjectsInfo.id),
        ),
      ),
      SliverToBoxAdapter(
        child: _buildContainer(
          context,
          ProducersView(subjectId: subjectsInfo.id),
        ),
      ),
      SliverToBoxAdapter(
        child: _buildContainer(
          context,
          RelatedView(subjectId: subjectsInfo.id),
        ),
      ),
      SliverToBoxAdapter(
        child: _buildContainer(
          context,
          InfoCommentView(subjectId: subjectId),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const String title = '简介';

    const fontWeightTitle = FontWeight.bold;

    const fontSizeTitle = 20.0;

    const fontWeight = FontWeight.w600;

    return Consumer(
      builder: (context, ref, _) {
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            final metrics = scrollInfo.metrics;

            if (metrics.axis == Axis.vertical &&
                scrollInfo is ScrollUpdateNotification) {
              ref
                  .read(subjectCommentsProvider(subjectId).notifier)
                  .onCommentsScroll(metrics);

              final bool shouldShowButton = scrollInfo.metrics.pixels >= 300;

              onScrollChanged?.call(shouldShowButton);
            }

            return false;
          },
          child: Builder(
            builder: (BuildContext context) {
              return CustomScrollView(
                key: const PageStorageKey<String>(title),
                slivers: <Widget>[
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final subjectsInfoAsync =
                          ref.watch(animeInfoProvider(subjectId));

                      return subjectsInfoAsync.when(
                        data: (subjectsInfo) => SliverMainAxisGroup(
                          slivers: _sliversForSubjectsInfo(
                            context,
                            subjectsInfo,
                            subjectId: subjectId,
                            title: title,
                            fontSizeTitle: fontSizeTitle,
                            fontWeightTitle: fontWeightTitle,
                            fontWeight: fontWeight,
                          ),
                        ),
                        loading: () => _skeletonSliver(context),
                        error: (_, __) => const SliverToBoxAdapter(
                          child: SizedBox.shrink(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// 构建带约束的容器
  Widget _buildContainer(
    BuildContext context,
    Widget child, {
    double topPadding = 0,
    AlignmentGeometry alignment = Alignment.center,
  }) {
    final leftPadding = MediaQuery.of(context).padding.left;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: LayoutConstant.maxWidth,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16 + leftPadding,
            right: 16,
            top: topPadding,
          ),
          child: child,
        ),
      ),
    );
  }

  ///骨架屏
  Widget _skeletonSliver(BuildContext context) {
    final isDark = SystemUtil.isDarkTheme(context);
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final containerColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).colorScheme.surface;
    final boxDecoration = BoxDecoration(
      color: containerColor,
      borderRadius: BorderRadius.circular(8.0),
    );

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 30,
                width: 80,
                decoration: boxDecoration,
              ),
              ...List.generate(6, (index) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    height: 20,
                    width: index == 5 ? 240 : double.infinity,
                    decoration: boxDecoration,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
