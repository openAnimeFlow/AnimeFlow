import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/models/item/subjects_item.dart';
import 'package:anime_flow/pages/anime_info/tags.dart';
import 'package:anime_flow/widget/text/expandable_text.dart';
import 'package:flutter/material.dart';

import 'details.dart';

/// 隐藏滚动条的ScrollBehavior
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

/// 简介页面
class InfoSynopsisView extends StatelessWidget {
  final Future<SubjectsItem?> subjectsItem;

  const InfoSynopsisView({super.key, required this.subjectsItem});

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
          child: CustomScrollView(
            key: const PageStorageKey<String>(title),
            slivers: <Widget>[
              // 注入重叠区域，防止内容被 Header 遮挡
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
              ),
              SliverToBoxAdapter(
                child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: PlayLayoutConstant.infoMaxWidth,
                      ),
                      child: Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          child: FutureBuilder<SubjectsItem?>(
                            future: subjectsItem,
                            builder: (context, snapshot) {
                              if (snapshot.data == null) {
                                //TODO 添加骨架屏
                                return const Text('加载中...');
                              } else {
                                final data = snapshot.data!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ExpandableText(
                                      title: title,
                                      fontSizeTitle: fontSizeTitle,
                                      fontWeightTitle: fontWeightTitle,
                                      text: data.summary,
                                      fontWeight: fontWeight,
                                    ),
                                    const SizedBox(height: 25),
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
                                    const SizedBox(height: 25),
                                    Details(
                                      title: '详情',
                                      subject: data,
                                      textSize: 13,
                                      textFontWeight: FontWeight.w600,
                                    )
                                  ],
                                );
                              }
                            },
                          )),
                    )),
              ),
            ],
          ),
        );
      },
    );
  }
}
