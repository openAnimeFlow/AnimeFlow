import 'package:animation_network_image/animation_network_image.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/collections_item.dart';
import 'package:anime_flow/models/item/user_info_item.dart';
import 'package:anime_flow/stores/user_info_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'collection_tab_view.dart';

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

  // 为每个 tab 类型缓存数据，key 是 type (1-5)
  final Map<int, CollectionsItem?> _collectionsCache = {};

  // 记录正在加载的 type
  final Set<int> _loadingTypes = {};

  // 记录每个 type 的 offset
  final Map<int, int> _offsets = {};

  // 记录每个 type 是否还有更多数据
  final Map<int, bool> _hasMore = {};

  List<String> get _tabs {
    const Map<int, String> collectionTypes = {
      1: '想看',
      2: '看过',
      3: '在看',
      4: '搁置',
      5: '抛弃',
    };
    final stats = widget.userInfoItem.stats.subject.two;
    return [
      '${collectionTypes[1]}\n${stats.one}',
      '${collectionTypes[2]}\n${stats.two}',
      '${collectionTypes[3]}\n${stats.three}',
      '${collectionTypes[4]}\n${stats.four}',
      '${collectionTypes[5]}\n${stats.five}',
    ];
  }

  void _getCollections(int type, {bool loadMore = false}) async {
    // 如果正在加载，则不再加载
    if (_loadingTypes.contains(type)) {
      return;
    }

    // 如果是加载更多，但没有更多数据，则不加载
    if (loadMore && (_hasMore[type] == false)) {
      return;
    }

    // 如果是首次加载，但已经有缓存数据，则不加载
    if (!loadMore && _collectionsCache.containsKey(type)) {
      return;
    }

    setState(() {
      _loadingTypes.add(type);
    });

    try {
      final offset = loadMore 
          ? (_offsets[type] ?? _collectionsCache[type]?.data.length ?? 0)
          : 0;
      final collections = await UserRequest.queryUserCollectionsService(
          type: type, limit: 20, offset: offset);

      setState(() {
        if (loadMore && _collectionsCache[type] != null) {
          // 追加数据
          _collectionsCache[type]!.data.addAll(collections.data);
        } else {
          // 首次加载
          _collectionsCache[type] = collections;
          _offsets[type] = 0; // 重置 offset
        }
        _offsets[type] = offset + collections.data.length;
        _hasMore[type] = collections.data.length == 20 && 
                         _collectionsCache[type]!.data.length < collections.total;
        _loadingTypes.remove(type);
      });
    } catch (e) {
      setState(() {
        _loadingTypes.remove(type);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    userInfoStore = Get.find<UserInfoStore>();

    // 监听 tab 切换，自动加载对应类型的数据（如果缓存中没有）
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final type = _tabController.index + 1;
        _getCollections(type);
      }
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
          return <Widget>[
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
                expandedHeight: _contentHeight +
                    statusBarHeight +
                    kToolbarHeight +
                    kTextTabBarHeight,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Padding(
                    padding:
                        const EdgeInsets.only(bottom: kTextTabBarHeight + 15),
                    child: _buildHeaderContent(statusBarHeight),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: _tabs.map((String name) {
                    final parts = name.split('\n');
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              parts[0],
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            parts.length > 1 ? parts[1] : '0',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
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
        body: CollectionTabView(
          collectionsCache: _collectionsCache,
          tabController: _tabController,
          tabs: _tabs,
          onLoad: (type) => _getCollections(type),
          onLoadMore: (type) => _getCollections(type, loadMore: true),
          loadingTypes: _loadingTypes,
          hasMore: _hasMore,
        ),
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
            Expanded(
              child: AnimatedOpacity(
                opacity: isPinned ? 1 : 0,
                duration: const Duration(milliseconds: 500),
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
                ),
              ),
            ),
            IconButton(
                onPressed: () {
                  setState(() {
                    // userInfoStore.clearUserInfo();
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
          Text.rich(TextSpan(
            text:
                userInfo.nickname != '' ? userInfo.nickname : userInfo.username,
            children: [
              TextSpan(
                  text: '@${userInfo.id}',
                  style: TextStyle(
                      fontSize: 16, color: Theme.of(context).disabledColor))
            ],
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          )),
        ],
      ),
    );
  }
}
