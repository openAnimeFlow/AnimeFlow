import 'dart:ui';

import 'package:anime_flow/models/item/flow/flow_users.dart';
import 'package:anime_flow/pages/user/provider/user_collection_provider.dart';
import 'package:anime_flow/pages/user/provider/user_collection_state.dart';
import 'package:anime_flow/providers/user/user_controller.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/animation_network_image.dart';
import 'package:anime_flow/widget/drop_down_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'collection_tab_view.dart';

enum _LoginOverflowAction { settings, playRecord, logout }

class UserView extends ConsumerStatefulWidget {
  final FlowUsers user;

  const UserView({super.key, required this.user});

  @override
  ConsumerState<UserView> createState() => _UserViewState();
}

class _UserViewState extends ConsumerState<UserView>
    with SingleTickerProviderStateMixin {
  final double _contentHeight = 200.0;
  late TabController _tabController;
  bool isPinned = false;

  final Map<int, GlobalKey<RefreshIndicatorState>> _refreshIndicatorKeys = {
    for (var type = 1; type <= 5; type++)
      type: GlobalKey<RefreshIndicatorState>(),
  };

  List<String> get _tabs => buildUserCollectionTabLabels(widget.user);

  Future<void> _showRefreshIndicatorForCurrentTab() async {
    await _refreshIndicatorKeys[_tabController.index + 1]?.currentState?.show();
  }

  @override
  void initState() {
    super.initState();
    // TODO 暂时默认为再看tab索引，后续从设置中获取
    _tabController = TabController(
      length: userCollectionTypeLabels.length,
      vsync: this,
      initialIndex: 2,
    );
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(userCollectionsProvider.notifier)
          .loadInitial(_tabController.index + 1);
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref
          .read(userCollectionsProvider.notifier)
          .loadInitial(_tabController.index + 1);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
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
          tabController: _tabController,
          tabs: _tabs,
          refreshIndicatorKeys: _refreshIndicatorKeys,
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    final user = widget.user;
    final currentType = _tabController.index + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Spacer(),
          AnimatedOpacity(
            opacity: isPinned ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: user.avatar.isNotEmpty
                      ? AnimationNetworkImage(
                          width: 30, height: 30, url: user.avatar)
                      : const Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 5),
                Text(
                  user.nickname.isNotEmpty ? user.nickname : user.email,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
          const Spacer(),
          if (SystemUtil.isDesktop)
            Consumer(
              builder: (context, ref, _) {
                final tabState = ref.watch(
                  userCollectionsProvider.select(
                    (state) => state.tabState(currentType),
                  ),
                );
                final canTriggerRefresh = tabState.data != null;
                final isRefreshButtonEnabled =
                    canTriggerRefresh && !tabState.isBusy;

                return IconButton(
                  tooltip: '刷新当前标签',
                  onPressed: isRefreshButtonEnabled
                      ? _showRefreshIndicatorForCurrentTab
                      : null,
                  icon: const Icon(Icons.refresh),
                );
              },
            ),
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
                _LoginOverflowAction.settings => (
                    Icons.settings_outlined,
                    '设置'
                  ),
                _LoginOverflowAction.playRecord => (
                    Icons.smart_display_outlined,
                    '播放记录'
                  ),
                _LoginOverflowAction.logout => (Icons.logout_outlined, '退出登录'),
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
                        Consumer(builder: (context, ref, _) {
                          return TextButton(
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();
                              await ref
                                  .read(userControllerProvider.notifier)
                                  .clearUserInfo();
                            },
                            child: const Text('确定'),
                          );
                        }),
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
    final user = widget.user;
    final hasAvatar = user.avatar.isNotEmpty;
    final hasBackground = user.background.isNotEmpty;
    final backgroundUrl = hasBackground
        ? user.background
        : (hasAvatar ? user.avatar : null);
    final blurSigma = hasBackground ? 0.0 : 15.0;
    return Stack(
      children: [
        if (backgroundUrl != null)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.4,
                child: LayoutBuilder(
                  builder: (context, boxConstraints) {
                    return ImageFiltered(
                      imageFilter: ImageFilter.blur(
                          sigmaX: blurSigma, sigmaY: blurSigma),
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Colors.transparent],
                            stops: [0.9, 1],
                          ).createShader(bounds);
                        },
                        child: AnimationNetworkImage(
                          url: backgroundUrl,
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
              if (hasAvatar)
                AnimationNetworkImage(
                  borderRadius: BorderRadius.circular(100),
                  url: user.avatar,
                  fit: BoxFit.cover,
                  width: 100,
                  height: 100,
                )
              else
                const Icon(Icons.person, size: 96),
              Text(
                user.nickname.isNotEmpty ? user.nickname : user.email,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${FormatTimeUtil.formatDate(user.createTime)}加入',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
