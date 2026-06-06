import 'dart:ui';

import 'package:anime_flow/features/my/my_controller_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/drop_down_menu.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/collections_item.dart';
import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:anime_flow/widget/bbcode/bbcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'collection_tab_view.dart';

enum _LoginOverflowAction { settings, playRecord, logout }

class UserView extends StatefulWidget {
  final UserInfoItem userInfoItem;

  const UserView({super.key, required this.userInfoItem});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> with SingleTickerProviderStateMixin {
  final double _contentHeight = 200.0; // 头部内容区域的高度
  late TabController _tabController;
  bool isPinned = false;

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

  Future<void> _getCollections(int type,
      {bool loadMore = false, bool refresh = false}) async {
    // 如果是刷新，允许重新加载
    if (!refresh) {
      // 如果正在加载，则不再加载
      if (_loadingTypes.contains(type)) {
        return;
      }

      // 如果是加载更多，但没有更多数据，则不加载
      if (loadMore && (_hasMore[type] == false)) {
        return;
      }

      // 如果是首次加载，但已经有缓存数据，则不加载
      if (!loadMore && _collectionsCache[type] != null) {
        return;
      }
    }

    setState(() {
      _loadingTypes.add(type);
    });

    try {
      final offset = loadMore && !refresh
          ? (_offsets[type] ?? _collectionsCache[type]?.data.length ?? 0)
          : 0;
      final collections = await UserRequest.userCollectionsService(
          type: type, limit: 20, offset: offset);

      setState(() {
        if (loadMore && !refresh && _collectionsCache[type] != null) {
          // 追加数据
          _collectionsCache[type]!.data.addAll(collections.data);
          _offsets[type] = offset + collections.data.length;
        } else {
          // 首次加载或刷新
          _collectionsCache[type] = collections;
          _offsets[type] = collections.data.length;
        }
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

  Future<void> _refreshCollections(int type) async {
    await _getCollections(type, refresh: true);
  }

  @override
  void initState() {
    super.initState();
    // TODO 暂时默认为再看tab索引，后续从设置中获取
    _tabController =
        TabController(length: _tabs.length, vsync: this, initialIndex: 2);
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
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildHeaderContent(statusBarHeight),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerHeight: 0,
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
          onRefresh: (type) => _refreshCollections(type),
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
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () =>
                UserSpaceRoute(name: userInfo.username).push(context),
            child: const Row(
              children: [
                Text(
                  '我的空间',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Icon(Icons.import_contacts)
              ],
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
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
          const Spacer(),
          DropDownMenu<_LoginOverflowAction>(
            items: _LoginOverflowAction.values,
            tooltip: '更多菜单',
            disableSelected: false,
            buttonBuilder: (context, _) => const Icon(
              Icons.notes_outlined,
              size: 30,
            ),
            itemBuilder: (context, action, _) {
              final (icon, label) = switch (action) {
                _LoginOverflowAction.settings =>
                  (Icons.settings_outlined, '设置'),
                _LoginOverflowAction.playRecord =>
                  (Icons.smart_display_outlined, '播放记录'),
                _LoginOverflowAction.logout =>
                  (Icons.logout_outlined, '退出登录'),
              };
              return SizedBox(
                width: 120,
                child: Row(
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                    Text(label),
                  ],
                ),
              );
            },
            onSelected: (action) {
              switch (action) {
                case _LoginOverflowAction.settings:
                  const SettingsRoute().push(context);
                case _LoginOverflowAction.playRecord:
                  const PlayRecordRoute().push(context);
                case _LoginOverflowAction.logout:
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('确认退出'),
                      content: const Text('确定要退出登录吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            ProviderScope.containerOf(context)
                                .read(myControllerProvider)
                                .clearUserInfo();
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent(double statusBarHeight) {
    final userInfo = widget.userInfoItem;
    final bio = userInfo.bio;
    return Stack(
      children: [
        // Positioned.fill(
        //   child: IgnorePointer(
        //     child: Opacity(
        //       opacity: 0.4,
        //       child: LayoutBuilder(
        //         builder: (context, boxConstraints) {
        //           return ImageFiltered(
        //             imageFilter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        //             child: ShaderMask(
        //               shaderCallback: (Rect bounds) {
        //                 return const LinearGradient(
        //                   begin: Alignment.topCenter,
        //                   end: Alignment.bottomCenter,
        //                   colors: [Colors.white, Colors.transparent],
        //                   stops: [0.8, 1],
        //                 ).createShader(bounds);
        //               },
        //               child: AnimationNetworkImage(
        //                 url: userInfo.avatar.large,
        //                 fit: BoxFit.cover,
        //               ),
        //             ),
        //           );
        //         },
        //       ),
        //     ),
        //   ),
        // ),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.4,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  return ImageFiltered(
                    imageFilter: ImageFilter.blur(
                        sigmaX: bio != null ? 0 : 15,
                        sigmaY: bio != null ? 0 : 15),
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Colors.transparent],
                          stops: [0.9, 1],
                        ).createShader(bounds);
                      },
                      child: bio != null
                          ? BBCodeWidget(
                              bbcode: userInfo.bio ?? '',
                              fit: BoxFit.cover,
                            )
                          : AnimationNetworkImage(
                              url: userInfo.avatar.large,
                              fit: BoxFit.cover,
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: AnimationNetworkImage(
                  url: userInfo.avatar.large,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(TextSpan(
                text: userInfo.nickname != ''
                    ? userInfo.nickname
                    : userInfo.username,
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
        )
      ],
    );
  }
}
