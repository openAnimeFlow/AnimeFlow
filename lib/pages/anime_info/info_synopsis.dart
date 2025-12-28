import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/pages/anime_info/characters.dart';
import 'package:anime_flow/pages/anime_info/related.dart';
import 'package:anime_flow/pages/anime_info/tags.dart';
import 'package:anime_flow/widget/text/expandable_text.dart';
import 'package:flutter/material.dart';

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
  final Future<SubjectsInfoItem?> subjectsItem;
  final ValueChanged<bool>? onScrollChanged;

  const InfoSynopsisView({
    super.key,
    required this.subjectsItem,
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
                child: FutureBuilder<SubjectsInfoItem?>(
                  future: widget.subjectsItem,
                  builder: (context, snapshot) {
                    final data = snapshot.data;
                    final leftPadding = MediaQuery.of(context).padding.left;

                    return CustomScrollView(
                      key: const PageStorageKey<String>(title),
                      slivers: <Widget>[
                        // 注入重叠区域，防止内容被 Header 遮挡
                        SliverOverlapInjector(
                          handle:
                              NestedScrollView.sliverOverlapAbsorberHandleFor(
                            context,
                          ),
                        ),

                        // 加载中状态
                        if (data == null)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('加载中...'),
                            ),
                          )
                        else ...[
                          // 简介
                          SliverToBoxAdapter(
                            child: _buildContainer(
                              leftPadding,
                              ExpandableText(
                                title: title,
                                fontSizeTitle: fontSizeTitle,
                                fontWeightTitle: fontWeightTitle,
                                text: data.summary,
                                fontWeight: fontWeight,
                              ),
                            ),
                          ),

                          // 标签
                          SliverToBoxAdapter(
                            child: _buildContainer(
                              leftPadding,
                              TagView(
                                title: '标签',
                                fontSizeTitle: fontSizeTitle,
                                fontWeightTitle: fontWeightTitle,
                                tags: data.tags,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                numbersSize: 10,
                                numbersWeight: FontWeight.w600,
                              ),
                              topPadding: 25,
                            ),
                          ),

                          // 详情
                          SliverToBoxAdapter(
                            child: _buildContainer(
                              leftPadding,
                              DetailsView(
                                title: '详情',
                                subject: data,
                                textSize: 13,
                                textFontWeight: FontWeight.w600,
                              ),
                              topPadding: 25,
                            ),
                          ),

                          // 角色
                          SliverToBoxAdapter(
                            child: _buildContainer(
                              leftPadding,
                              CharactersView(
                                title: '角色',
                                subjectsId: data.id,
                              ),
                            ),
                          ),

                          // 关联条目
                          SliverToBoxAdapter(
                            child: _buildContainer(
                              leftPadding,
                              RelatedView(
                                title: '关联条目',
                                subjectId: data.id,
                              ),
                            ),
                          ),

                          // 评论
                          SliverToBoxAdapter(
                            child: _buildContainer(
                              leftPadding,
                              CommentView(
                                key: _commentViewKey,
                                subjectId: data.id,
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

  /// 构建带约束的容器
  Widget _buildContainer(double leftPadding, Widget child,
      {double topPadding = 0}) {
    return Align(
      alignment: Alignment.center,
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
