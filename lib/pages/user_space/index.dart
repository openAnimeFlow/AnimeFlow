import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:anime_flow/repository/providers/repository_providers.dart';
import 'package:anime_flow/pages/user_space/statistics/index.dart';
import 'package:anime_flow/pages/user_space/user_stores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'app_bar_title.dart';
import 'collect/index.dart';
import 'header_content.dart';
import 'intro.dart';



class UserSpacePage extends ConsumerStatefulWidget {
  final String username;

  const UserSpacePage({super.key, required this.username});

  @override
  ConsumerState<UserSpacePage> createState() => _UserSpacePageState();
}

class _UserSpacePageState extends ConsumerState<UserSpacePage>
    with SingleTickerProviderStateMixin {
  final double _contentHeight = 200.0; // 头部内容区域的高度
  late TabController _tabController;

  String get username => widget.username;
  bool isLoading = false;
  UserInfoItem? userInfo;
  bool isPinned = false;

  final List<String> _tabs = ['介绍', '收藏', '统计', '时间线'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _getUserInfo();
  }

  //获取用户基础信息
  Future<void> _getUserInfo() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final userInfo = await ref
          .read(userRepositoryProvider)
          .getUserProfile(username);
      if (!mounted) return;
      Get.put(UserSpaceStores(userInfo));
      setState(() {
        this.userInfo = userInfo;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    Get.delete<UserSpaceStores>();
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
                      title: BarTitleView(
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
                          child: HeaderContent(
                            userInfo: userInfo!,
                          ),
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
                  IntroView(userInfo: userInfo!),
                  const CollectView(),
                  const StatisticsView(),
                  Builder(builder: (context) => _buildTimelineTab(context)),
                ],
              ),
            ),
          );
        }
      }),
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
