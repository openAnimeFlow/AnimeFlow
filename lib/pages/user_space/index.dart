import 'dart:ui';

import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/bbcode/bbcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

part 'app_bar_title.dart';
part 'header_content.dart';
part 'intro.dart';

class UserSpacePage extends StatefulWidget {
  const UserSpacePage({super.key});

  @override
  State<UserSpacePage> createState() => _UserSpacePageState();
}

class _UserSpacePageState extends State<UserSpacePage>
    with SingleTickerProviderStateMixin {
  final double _contentHeight = 200.0; // 头部内容区域的高度
  late final String username;
  late TabController _tabController;
  bool isLoading = false;
  UserInfoItem? userInfo;
  bool isPinned = false;

  final List<String> _tabs = ['介绍', '收藏', '统计', '时间线'];

  @override
  void initState() {
    super.initState();
    username = Get.arguments as String;
    _tabController = TabController(length: _tabs.length, vsync: this);
    _getUserInfo();
  }

  //获取用户基础信息
  void _getUserInfo() async {
    setState(() {
      isLoading = true;
    });
    final userInfo = await UserRequest.queryUserInfoService(username);
    setState(() {
      this.userInfo = userInfo;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Builder(builder: (context) {
        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (userInfo == null) {
          return const Center(
            child: Text('无法查询到用户信息'),
          );
        } else {
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.depth == 0 &&
                  notification is ScrollUpdateNotification) {
                final bool isPinned =
                    notification.metrics.pixels >= _contentHeight;
                if (this.isPinned != isPinned) {
                  setState(() {
                    this.isPinned = isPinned;
                  });
                }
              }
              return false;
            },
            child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                    sliver: SliverAppBar(
                      automaticallyImplyLeading: false,
                      titleSpacing: 0,
                      title: AppBarTitleView(
                          userInfo: userInfo!, isPinned: isPinned),
                      pinned: true,
                      floating: false,
                      snap: false,
                      elevation: isPinned ? 4.0 : 0.0,
                      forceElevated: isPinned,
                      expandedHeight: _contentHeight +
                          statusBarHeight +
                          kToolbarHeight +
                          kTextTabBarHeight,
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.pin,
                        background: Padding(
                          padding:
                              const EdgeInsets.only(bottom: kTextTabBarHeight),
                          child: HeaderContent(userInfo: userInfo!,),
                        ),
                      ),
                      bottom: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerHeight: 0,
                        tabs: _tabs.map((String name) {
                          return Tab(
                            text: name,
                          );
                        }).toList(),
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  Builder(builder: (context) => IntroView(userInfo: userInfo!)),
                  Builder(builder: (context) => _buildCollectionsTab(context)),
                  Builder(builder: (context) => _buildStatsTab(context)),
                  Builder(builder: (context) => _buildTimelineTab(context)),
                ],
              ),
            ),
          );
        }
      }),
    );
  }


  Widget _buildCollectionsTab(BuildContext context) {
    final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);

    return CustomScrollView(
      slivers: <Widget>[
        SliverOverlapInjector(handle: handle),
        const SliverFillRemaining(
          child: Center(
            child: Text('收藏功能待实现'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab(BuildContext context) {
    final userInfo = this.userInfo!;
    final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);

    return CustomScrollView(
      slivers: <Widget>[
        SliverOverlapInjector(handle: handle),
        const SliverFillRemaining(
          child: Center(
            child: Text('功能待实现'),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTab(BuildContext context) {
    final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);

    return CustomScrollView(
      slivers: <Widget>[
        SliverOverlapInjector(handle: handle),
        const SliverFillRemaining(
          child: Center(
            child: Text('时间线功能待实现'),
          ),
        ),
      ],
    );
  }
}
