import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/pages/anime_info/characters.dart';
import 'package:anime_flow/pages/anime_info/related.dart';
import 'package:anime_flow/pages/anime_info/tags.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:anime_flow/widget/text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'details.dart';
import 'comment.dart';

/// 隐藏滚动条的ScrollBehavior
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

/// 简介页面
class InfoSynopsisView extends StatefulWidget {
  final SubjectsInfoItem? subjectsInfo;
  final ValueChanged<bool>? onScrollChanged;

  const InfoSynopsisView({
    super.key,
    this.subjectsInfo,
    this.onScrollChanged,
  });

  @override
  State<InfoSynopsisView> createState() => _InfoSynopsisViewState();
}

class _InfoSynopsisViewState extends State<InfoSynopsisView> {
  final GlobalKey<CommentViewState> _commentViewKey =
      GlobalKey<CommentViewState>();

  @override
  Widget build(BuildContext context) {
    const String title = '简介';
    const fontWeightTitle = FontWeight.bold;
    const fontSizeTitle = 20.0;
    const fontWeight = FontWeight.w600;

    return Builder(
      builder: (BuildContext context) {
        return ScrollConfiguration(
          behavior: _NoScrollbarBehavior(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              // 只处理垂直滚动的更新事件
              if (scrollInfo.metrics.axis == Axis.vertical &&
                  scrollInfo is ScrollUpdateNotification) {
                // 通知 CommentView 检查是否需要加载更多
                _commentViewKey.currentState
                    ?.checkAndLoadMore(scrollInfo.metrics);

                // 监听页面滚动位置，通知父组件更新按钮显示状态
                final bool shouldShowButton = scrollInfo.metrics.pixels >= 300;
                widget.onScrollChanged?.call(shouldShowButton);
              }
              return false;
            },
            child: Builder(
              builder: (context) {
                return CustomScrollView(
                  key: const PageStorageKey<String>(title),
                  slivers: <Widget>[
                    // 注入重叠区域，防止内容被 Header 遮挡
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),

                    // 加载中骨架屏
                    if (widget.subjectsInfo == null)
                      SliverToBoxAdapter(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _skeleton(context)),
                      )
                    else ...[
                      // 简介
                      SliverToBoxAdapter(
                        child: _buildContainer(
                          ExpandableText(
                            title: title,
                            fontSizeTitle: fontSizeTitle,
                            fontWeightTitle: fontWeightTitle,
                            text: widget.subjectsInfo!.summary,
                            fontWeight: fontWeight,
                          ),
                        ),
                      ),

                      // 标签
                      SliverToBoxAdapter(
                        child: _buildContainer(
                          topPadding: 25,
                          alignment: Alignment.topLeft,
                          TagView(
                            title: '标签',
                            fontSizeTitle: fontSizeTitle,
                            fontWeightTitle: fontWeightTitle,
                            tags: widget.subjectsInfo!.tags,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            numbersSize: 10,
                            numbersWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // 详情
                      SliverToBoxAdapter(
                        child: _buildContainer(
                          DetailsView(
                            title: '详情',
                            subject: widget.subjectsInfo!,
                            textSize: 13,
                            textFontWeight: FontWeight.w600,
                          ),
                          topPadding: 25,
                        ),
                      ),

                      // 角色
                      SliverToBoxAdapter(
                        child: _buildContainer(
                          CharactersView(
                            title: '角色',
                            subjectsId: widget.subjectsInfo!.id,
                          ),
                        ),
                      ),

                      // 关联条目
                      SliverToBoxAdapter(
                        child: _buildContainer(
                          RelatedView(
                            title: '关联条目',
                            subjectId: widget.subjectsInfo!.id,
                          ),
                        ),
                      ),

                      // 评论
                      SliverToBoxAdapter(
                        child: _buildContainer(
                          CommentView(
                            key: _commentViewKey,
                            subjectId: widget.subjectsInfo!.id,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  ///骨架屏
  Widget _skeleton(BuildContext context) {
    final isDark = Utils.isDarkTheme(context);
    final baseColor = isDark ? Colors.grey[400]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[300]! : Colors.grey[100]!;
    final containerColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).colorScheme.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 30,
            width: 150,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 25,
            width: 400,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 25,
            width: 400,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 25,
            width: 400,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 25,
            width: 400,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建带约束的容器
  Widget _buildContainer(Widget child,
      {double topPadding = 0, AlignmentGeometry alignment = Alignment.center}) {
    final leftPadding = MediaQuery.of(context).padding.left;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: PlayLayoutConstant.maxWidth,
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
}
