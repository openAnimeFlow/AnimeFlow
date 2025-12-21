import 'package:animation_network_image/animation_network_image.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/stores/TokenStorage.dart';
import 'package:anime_flow/stores/user_info_store.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import 'my_controller.dart';

// SliverPersistentHeader 委托类，用于实现吸顶的 TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
  late AppLinks _appLinks;
  final double _contentHeight = 200.0; // 头部内容区域的高度
  bool isPinned = false;
  Future<void>? _getUserInfoFuture;
  TokenItem? token;
  late TabController _tabController;
  late UserInfoStore userInfoStore;

  // Tab 标签
  static const List<String> _tabs = ['收藏', '评论', '历史'];

  // 静态数据
  final List<Map<String, dynamic>> _listItems = [
    {'title': '我的收藏', 'icon': Icons.favorite, 'count': 0},
    {'title': '我的评论', 'icon': Icons.comment, 'count': 0},
    {'title': '观看历史', 'icon': Icons.history, 'count': 0},
    {'title': '设置', 'icon': Icons.settings, 'count': null},
    {'title': '关于', 'icon': Icons.info, 'count': null},
  ];

  @override
  void initState() {
    super.initState();
    userInfoStore = Get.find<UserInfoStore>();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initialize() async {
    token = await tokenStorage.getToken();

    _appLinks = AppLinks();
    _listenForDeepLink(_appLinks);
  }

  Future<void> _listenForDeepLink(AppLinks appLinks) async {
    try {
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) {
        await MyController.handleDeepLink(initialLink.toString());
        // 深度链接处理完成后，更新 token 并刷新用户信息
        token = await tokenStorage.getToken();
        _getUserInfo();
      }

      // 监听深度链接
      appLinks.uriLinkStream.listen((Uri uri) async {
        await MyController.handleDeepLink(uri.toString());
        // 深度链接处理完成后，更新 token 并刷新用户信息
        token = await tokenStorage.getToken();
        _getUserInfo();
      });
    } catch (e) {
      Logger().e("Error in deep link listener: $e");
    }
  }

  Future<void> _getUserInfo() async {
    // 如果已有正在进行的请求，不重复请求
    if (_getUserInfoFuture != null) {
      return;
    }

    _getUserInfoFuture = _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      if (token != null && mounted) {
        final userInfo =
            await UserRequest.queryUserInfoService(token!.userId.toString());
        if (mounted) {
          userInfoStore.userInfo.value = userInfo;
        }
      }
    } catch (e) {
      Logger().e("Error fetching user info: $e");
    } finally {
      if (mounted) {
        _getUserInfoFuture = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 状态栏高度
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              notification is ScrollUpdateNotification) {
            final bool isPinned = notification.metrics.pixels >= _contentHeight;
            if (this.isPinned != isPinned) {
              setState(() {
                this.isPinned = isPinned;
              });
            }
          }
          return false;
        },
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            final widgets = <Widget>[
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverAppBar(
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  title: _buildAppBarTitle(),
                  pinned: true,
                  floating: false,
                  snap: false,
                  elevation: isPinned ? 0 : 0.0,
                  forceElevated: isPinned,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  expandedHeight:
                      _contentHeight + statusBarHeight + kToolbarHeight,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _buildHeaderContent(statusBarHeight),
                    ),
                  ),
                ),
              ),
            ];

            widgets.add(
              Obx(() {
                if (userInfoStore.userInfo.value != null) {
                  return SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        tabs: _tabs
                            .map((String name) => Tab(text: name))
                            .toList(),
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(); // 返回空的widget而不是null
              }),
            );
            return widgets;
          },
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Text(
              '我的',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isPinned)
              Obx(() {
                final userInfo = userInfoStore.userInfo.value;
                if (userInfo != null) {
                  return Expanded(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: AnimationNetworkImage(
                            width: 30, height: 30, url: userInfo.avatar.large),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        userInfo.nickname != ''
                            ? userInfo.nickname
                            : userInfo.username,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      )
                    ],
                  ));
                } else {
                  return const Spacer();
                }
              })
            else
              const Spacer(),
            const Icon(Icons.settings_outlined)
          ],
        ));
  }

  Widget _buildHeaderContent(double statusBarHeight) {
    return Obx(() {
      if (userInfoStore.userInfo.value != null) {
        final userInfo = userInfoStore.userInfo.value;
        return Container(
          padding: EdgeInsets.only(top: statusBarHeight + kToolbarHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: AnimationNetworkImage(
                    url: userInfo!.avatar.large,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userInfo.nickname != '' ? userInfo.nickname : userInfo.username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
          padding: EdgeInsets.only(top: statusBarHeight + kToolbarHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 用户头像
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 60, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // 用户名
              const Text(
                '未登录',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // 登录按钮
              ElevatedButton(
                onPressed: () {
                  MyController.openOAuthPage();
                },
                child: const Text('登录授权'),
              ),
            ],
          ),
        );
      }
    });
  }

  Widget _buildBody() {
    return Obx(() {
      if (userInfoStore.userInfo.value == null) {
        return Builder(
          builder: (BuildContext context) {
            return CustomScrollView(
              slivers: <Widget>[
                SliverOverlapInjector(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        if (index == 0) {
                          // 第一个项目：查看token按钮
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.token),
                              title: const Text('查看Token'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                tokenStorage.getToken().then((value) {
                                  Logger().i(value);
                                });
                              },
                            ),
                          );
                        }
                        final item = _listItems[index - 1];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(item['icon'] as IconData),
                            title: Text(item['title'] as String),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item['count'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${item['count']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              // TODO: 处理点击事件
                            },
                          ),
                        );
                      },
                      childCount: _listItems.length + 1,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        return TabBarView(
            controller: _tabController,
            children: _tabs.map((String name) {
              return Builder(
                builder: (BuildContext context) {
                  return CustomScrollView(
                    slivers: <Widget>[
                      SliverOverlapInjector(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Icon(_getTabIcon(name)),
                                  title: Text('$name 项目 ${index + 1}'),
                                  subtitle: Text('这是 $name 页面的静态数据'),
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              );
                            },
                            childCount: 10, // 静态数据项数
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }).toList());
      }
    });
  }

  IconData _getTabIcon(String tabName) {
    switch (tabName) {
      case '收藏':
        return Icons.favorite;
      case '评论':
        return Icons.comment;
      case '历史':
        return Icons.history;
      default:
        return Icons.info;
    }
  }
}
