import 'dart:ui';
import 'dart:async';

import 'package:anime_flow/shared/navigation/settings_destination.dart';
import 'package:anime_flow/features/user/application/collection_revision_provider.dart';
import 'collection_sync_pending_banner.dart';
import 'package:anime_flow/shared/models/flow/flow_users.dart';
import 'package:anime_flow/shared/models/enums/collection_sort.dart';
import 'package:anime_flow/features/user/application/user_collection_provider.dart';
import 'package:anime_flow/features/user/application/user_collection_state.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/core/utils/format_time_util.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/shared/models/enums/collect_type.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/debounced_image_width.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'collection_filter_dialog.dart';
import 'user_collection_tabs.dart';

enum _LoginOverflowAction { settings, playRecord, downloads, logout }

class UserCenterView extends ConsumerStatefulWidget {
  final FlowUsers user;

  const UserCenterView({super.key, required this.user});

  @override
  ConsumerState<UserCenterView> createState() => _UserViewState();
}

class _UserViewState extends ConsumerState<UserCenterView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final StreamSubscription<CollectType> _collectionSettingSubscription;
  final _isPinned = ValueNotifier(false);
  bool isHideUserInfo = true;

  final Map<int, GlobalKey<RefreshIndicatorState>> _refreshIndicatorKeys = {
    for (var type = 1; type <= 5; type++)
      type: GlobalKey<RefreshIndicatorState>(),
  };

  List<String> _buildTabs(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return buildUserCollectionTabLabels(widget.user, [
      l10n.collectionPlanToWatch,
      l10n.collectionWatched,
      l10n.collectionWatching,
      l10n.collectionOnHold,
      l10n.collectionAbandoned,
    ]);
  }

  int get _currentType => _tabController.index + 1;

  Future<void> _showRefreshIndicatorForCurrentTab() async {
    await _refreshIndicatorKeys[_currentType]?.currentState?.show();
  }

  Future<void> _showCollectionFilterDialog() async {
    final currentType = _currentType;
    final tab = ref.read(userCollectionsProvider).tabState(currentType);
    final filters = await showDialog<CollectionFilterResult>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => CollectionFilterDialog(
        initialKeyword: tab.keyword ?? '',
        initialSort: AppSettings.getCollectionSort(currentType),
      ),
    );
    if (filters == null || !mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(userCollectionsProvider.notifier).applyFilters(
            currentType,
            keyword: filters.keyword,
            sort: filters.sort,
          );
    });
  }

  /// 切换用户信息显示状态
  void _toggleUserInfoVisibility() {
    setState(() {
      isHideUserInfo = !isHideUserInfo;
    });
  }

  @override
  void didUpdateWidget(covariant UserCenterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id == widget.user.id) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final notifier = ref.read(userCollectionsProvider.notifier);
      notifier.reset();
      notifier.loadInitial(_currentType);
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: userCollectionTypeLabels.length,
      vsync: this,
      initialIndex: AppSettings.defaultCollectionType.value - 1,
    );
    _tabController.addListener(_onTabChanged);
    _collectionSettingSubscription =
        AppSettings.watchDefaultCollectionType().listen((type) {
      final index = type.value - 1;
      if (mounted && _tabController.index != index) {
        _tabController.index = index;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(userCollectionsProvider.notifier).loadInitial(_currentType);
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
      ref.read(userCollectionsProvider.notifier).loadInitial(_currentType);
    }
  }

  @override
  void dispose() {
    _collectionSettingSubscription.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _isPinned.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(collectionRevisionProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(userCollectionsProvider.notifier).loadInitial(_currentType);
        }
      });
    });
    final tabs = _buildTabs(context);
    // 同一尺寸档位内复用页面；用户信息、标签或显示状态更新时重新创建缓存。
    Widget? page;
    double? previousHeight;
    double? previousTopPadding;
    ThemeData? previousTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentHeight = switch (constraints.maxWidth) {
          >= 1440 => 430.0,
          >= 1100 => 320.0,
          >= 840 => 260.0,
          _ => 200.0,
        };
        final topPadding = MediaQuery.paddingOf(context).top;
        final theme = Theme.of(context);
        if (page == null ||
            previousHeight != contentHeight ||
            previousTopPadding != topPadding ||
            previousTheme != theme) {
          previousHeight = contentHeight;
          previousTopPadding = topPadding;
          previousTheme = theme;
          page = _buildUserPage(context, tabs, contentHeight);
        }
        return page!;
      },
    );
  }

  Widget _buildUserPage(
    BuildContext context,
    List<String> tabs,
    double contentHeight,
  ) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final header = ValueListenableBuilder<bool>(
      valueListenable: _isPinned,
      builder: (context, isPinned, child) => SliverAppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: _buildAppBarTitle(context, isPinned),
        pinned: true,
        floating: false,
        snap: false,
        elevation: isPinned ? 4.0 : 0.0,
        forceElevated: isPinned,
        expandedHeight: contentHeight +
            statusBarHeight +
            kToolbarHeight +
            kTextTabBarHeight,
        flexibleSpace: child,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerHeight: 0,
          tabs: tabs.map((String name) {
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
      child: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: RepaintBoundary(child: _buildHeaderContent()),
        ),
      ),
    );
    return Scaffold(
      bottomNavigationBar: const CollectionSyncPendingBanner(),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              notification.metrics.axis == Axis.vertical &&
              notification is ScrollUpdateNotification) {
            _isPinned.value = notification.metrics.pixels >= contentHeight;
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
                sliver: header,
              ),
            ];
          },
          body: UserCollectionTabs(
            tabController: _tabController,
            tabs: tabs,
            refreshIndicatorKeys: _refreshIndicatorKeys,
          ),
        ),
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, _) {
          final (keyword, sort) = ref.watch(
            userCollectionsProvider.select(
              (state) {
                final tab = state.tabState(_currentType);
                return (tab.keyword, tab.sort);
              },
            ),
          );
          final l10n = AppLocalizations.of(context);
          if ((keyword == null || keyword.isEmpty) &&
              sort == CollectionSort.defaultSort) {
            return FloatingActionButton(
              heroTag: null,
              tooltip: l10n.filterCollection,
              onPressed: _showCollectionFilterDialog,
              child: const Icon(Icons.tune),
            );
          }

          return FloatingActionButton.extended(
            heroTag: null,
            tooltip: l10n.filterCollection,
            onPressed: _showCollectionFilterDialog,
            icon: const Icon(Icons.tune),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                [
                  if (keyword != null && keyword.isNotEmpty) keyword,
                  if (sort == CollectionSort.watch) l10n.collectionSortWatch,
                ].join(' · '),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBarTitle(BuildContext context, bool isPinned) {
    final user = widget.user;
    final currentType = _currentType;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ClipRect(
            child: AnimatedSlide(
              offset: isPinned ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: IgnorePointer(
                ignoring: !isPinned,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: user.avatar != null && user.avatar!.isNotEmpty
                          ? DebouncedImageWidth(
                              width: 30,
                              builder: (context, cacheWidth) =>
                                  AnimationNetworkImage(
                                width: 30,
                                height: 30,
                                memCacheWidth: cacheWidth,
                                gaplessResize: true,
                                url: user.avatar!,
                              ),
                            )
                          : const Icon(Icons.person, size: 30),
                    ),
                    const SizedBox(width: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.nickname.isNotEmpty ? user.nickname : user.email,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          FormatTimeUtil.formatDate(user.createTime),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _toggleUserInfoVisibility,
            tooltip: isHideUserInfo ? l10n.showUserInfo : l10n.hideUserInfo,
            icon: Icon(
              isHideUserInfo ? Icons.visibility : Icons.visibility_off,
            ),
          ),
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
                  tooltip: l10n.refreshCurrentTab,
                  onPressed: isRefreshButtonEnabled
                      ? _showRefreshIndicatorForCurrentTab
                      : null,
                  icon: const Icon(Icons.refresh),
                );
              },
            ),
          DropDownMenu<_LoginOverflowAction>(
            items: _LoginOverflowAction.values,
            tooltip: l10n.moreMenu,
            disableSelected: false,
            buttonBuilder: (context, _) => const Icon(
              Icons.notes_outlined,
              size: 30,
            ),
            itemBuilder: (context, action, _) {
              final (icon, label) = switch (action) {
                _LoginOverflowAction.settings => (
                    Icons.settings_outlined,
                    l10n.settings
                  ),
                _LoginOverflowAction.playRecord => (
                    Icons.smart_display_outlined,
                    l10n.playbackHistory
                  ),
                _LoginOverflowAction.downloads => (
                    Icons.cloud_download_outlined,
                    l10n.downloadsTitle
                  ),
                _LoginOverflowAction.logout => (
                    Icons.logout_outlined,
                    l10n.logout
                  ),
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
                  appNavigatorOf(context).openSettings<void>(context,
                      destination: SettingsDestination.menu);
                case _LoginOverflowAction.playRecord:
                  appNavigatorOf(context).openPlayRecord<void>(context);
                case _LoginOverflowAction.downloads:
                  appNavigatorOf(context).openDownload<void>(context);
                case _LoginOverflowAction.logout:
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(l10n.confirmLogout),
                      content: Text(l10n.logoutConfirmation),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(l10n.cancel),
                        ),
                        Consumer(builder: (context, ref, _) {
                          return TextButton(
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();
                              await ref
                                  .read(accountControllerProvider)
                                  .clearUserInfo();
                            },
                            child: Text(l10n.confirm),
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

  Widget _buildHeaderContent() {
    final user = widget.user;
    final l10n = AppLocalizations.of(context);
    final hasAvatar = user.avatar != null && user.avatar!.isNotEmpty;
    final hasBackground = user.background?.isNotEmpty ?? false;
    final backgroundUrl =
        hasBackground ? user.background : (hasAvatar ? user.avatar : null);
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
                      enabled: blurSigma > 0,
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
                        child: DebouncedImageWidth(
                          width: boxConstraints.maxWidth,
                          builder: (context, cacheWidth) =>
                              AnimationNetworkImage(
                            url: backgroundUrl,
                            memCacheWidth: cacheWidth,
                            gaplessResize: true,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        if (isHideUserInfo)
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasAvatar)
                  DebouncedImageWidth(
                    width: 100,
                    builder: (context, cacheWidth) => AnimationNetworkImage(
                      borderRadius: BorderRadius.circular(100),
                      url: user.avatar!,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                      memCacheWidth: cacheWidth,
                      gaplessResize: true,
                    ),
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
                  l10n.joinedDate(FormatTimeUtil.formatDate(user.createTime)),
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
