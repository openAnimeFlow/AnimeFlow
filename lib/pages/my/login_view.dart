import 'package:animation_network_image/animation_network_image.dart';
import 'package:anime_flow/models/item/user_info_item.dart';
import 'package:anime_flow/stores/user_info_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginView extends StatefulWidget {
  final UserInfoItem userInfoItem;

  const LoginView({super.key, required this.userInfoItem});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  final double _contentHeight = 200.0; // 头部内容区域的高度
  late TabController _tabController;
  bool isPinned = false;
  late UserInfoStore userInfoStore;

  List<String> get _tabs {
    const Map<int, String> collectionTypes = {
      1: '抛弃',
      2: '想看',
      3: '在看',
      4: '搁置',
      5: '看过',
    };
    return [
      '${collectionTypes[1]}',
      '${collectionTypes[2]}',
      '${collectionTypes[3]}',
      '${collectionTypes[4]}',
      '${collectionTypes[5]}',
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    userInfoStore = Get.find<UserInfoStore>();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return NotificationListener<ScrollNotification>(
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
                elevation: isPinned ? 4.0 : 0.0,
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

          widgets.add(SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: _tabs.map((String name) => Tab(text: name)).toList(),
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ));
          return widgets;
        },
        body: _buildBody(),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    final userInfo = widget.userInfoItem;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Text(
              '我的',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isPinned)
              Expanded(
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
              ))
            else
              const Spacer(),
            IconButton(
                onPressed: () {
                  setState(() {
                    userInfoStore.clearUserInfo();
                  });
                },
                icon: const Icon(Icons.settings_outlined))
          ],
        ));
  }

  Widget _buildHeaderContent(double statusBarHeight) {
    final userInfo = widget.userInfoItem;
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
                url: userInfo.avatar.large,
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
  }

  Widget _buildBody() {
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
}

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
