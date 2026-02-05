import 'dart:math';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/actor_item.dart';
import 'package:anime_flow/models/item/bangumi/related_subjects_item.dart';
import 'package:anime_flow/models/item/bangumi/staff_item.dart';
import 'package:anime_flow/models/item/bangumi/subject_comments_item.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/star.dart';
import 'package:anime_flow/widget/text/expandable_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
part '_comment.dart';
part '_related.dart';
part '_producers.dart';
part '_characters.dart';
part '_details.dart';
part '_tags.dart';

/// 隐藏滚动条的ScrollBehavior
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

/// 条目详情信息展示ui
class InfoSynopsisView extends StatefulWidget {
  final int subjectsId;
  final SubjectsInfoItem? subjectsInfo;
  final ValueChanged<bool>? onScrollChanged;

  const InfoSynopsisView({
    super.key,
    this.subjectsInfo,
    this.onScrollChanged,
    required this.subjectsId,
  });

  @override
  State<InfoSynopsisView> createState() => _InfoSynopsisViewState();
}

class _InfoSynopsisViewState extends State<InfoSynopsisView> {
  final GlobalKey<_CommentViewState> _commentViewKey =
      GlobalKey<_CommentViewState>();

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
                          _TagView(
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
                          _DetailsView(
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
                          _CharactersView(subjectsId: widget.subjectsId),
                        ),
                      ),

                      //制作人
                      SliverToBoxAdapter(
                        child: _buildContainer(
                          _ProducersView(subjectId: widget.subjectsId),
                        ),
                      ),

                      // 关联条目
                      SliverToBoxAdapter(
                        child: _buildContainer(
                          _RelatedView(subjectId: widget.subjectsId),
                        ),
                      ),

                      // 评论
                      SliverToBoxAdapter(
                        child: _buildContainer(
                          _CommentView(
                            key: _commentViewKey,
                            subjectId: widget.subjectsId,
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
    final isDark = SystemUtil.isDarkTheme(context);
    final baseColor = isDark ? Colors.grey[400]! : Colors.grey[100]!;
    final highlightColor = isDark ? Colors.grey[300]! : Colors.grey[50]!;
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
