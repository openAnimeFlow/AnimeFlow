import 'dart:ui';
import 'dart:async';

import 'package:anime_flow/shared/navigation/settings_destination.dart';
import 'package:anime_flow/features/user/application/collection_refresh_provider.dart';
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
import 'package:anime_flow/shared/widgets/bottom_occlusion.dart';
import 'package:anime_flow/shared/widgets/glass_capsule.dart';
import 'package:anime_flow/shared/widgets/glass_tab_bar.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:anime_flow/shared/widgets/top_gradient_mask.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'collection_filter_form.dart';
import 'user_collection_tabs.dart';

enum _LoginOverflowAction {
  settings(Icons.settings_outlined),
  favoriteWallpapers(Icons.image_outlined),
  playRecord(Icons.smart_display_outlined),
  downloads(Icons.cloud_download_outlined),
  logout(Icons.logout_outlined);

  const _LoginOverflowAction(this.icon);

  final IconData icon;

  String label(AppLocalizations l10n) => switch (this) {
        _LoginOverflowAction.settings => l10n.settings,
        _LoginOverflowAction.favoriteWallpapers => l10n.favoriteWallpapers,
        _LoginOverflowAction.playRecord => l10n.playbackHistory,
        _LoginOverflowAction.downloads => l10n.downloadsTitle,
        _LoginOverflowAction.logout => l10n.logout,
      };
}

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
  late final _scrollController = ScrollController()
    ..addListener(_updatePinnedState);
  final _isPinned = ValueNotifier(false);
  final _showUserInfo = ValueNotifier(true);
  double _collapseExtent = 0;

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

  void _updatePinnedState() {
    if (!mounted || !_scrollController.hasClients) return;
    // 只在吸顶状态改变时通知顶部栏，避免每个滚动帧都重新构建。
    _isPinned.value = _scrollController.offset >= _collapseExtent;
  }

  @override
  void dispose() {
    _collectionSettingSubscription.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    _isPinned.dispose();
    _showUserInfo.dispose();
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
    // 同一尺寸档位内复用页面；用户资料或标签更新时重新创建缓存。
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
    _collapseExtent = contentHeight + statusBarHeight;
    // 尺寸变化或恢复滚动位置后，在布局完成时同步一次吸顶状态。
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePinnedState());
    final header = SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      forceMaterialTransparency: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      titleSpacing: 0,
      title: ValueListenableBuilder<bool>(
        valueListenable: _isPinned,
        builder: (context, isPinned, _) => _buildAppBarTitle(context, isPinned),
      ),
      expandedHeight: _collapseExtent + kToolbarHeight + GlassTabBar.height,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: RepaintBoundary(child: _buildHeaderContent()),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _isPinned,
            builder: (context, isPinned, child) =>
                isPinned ? child! : const SizedBox.shrink(),
            child: const TopGradientMask(),
          ),
        ],
      ),
      bottom: GlassTabBar(
        controller: _tabController,
        labels: tabs,
        isScrollable: true,
        labelBuilder: _buildCollectionTabLabel,
      ),
    );
    return Scaffold(
      bottomNavigationBar: const CollectionSyncPendingBanner(),
      body: NestedScrollView(
        controller: _scrollController,
        // 越界反馈由内层收藏列表处理，外层只负责折叠顶部栏。
        scrollBehavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          overscroll: false,
        ),
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                context,
              ),
              sliver: MediaQuery.removePadding(
                  context: context, removeLeft: true, child: header),
            ),
          ];
        },
        body: UserCollectionTabs(
          tabController: _tabController,
          tabs: tabs,
          refreshIndicatorKeys: _refreshIndicatorKeys,
        ),
      ),
      floatingActionButtonLocation:
          OcclusionAwareFabLocation(BottomOcclusionScope.of(context)),
      floatingActionButton: Consumer(
        builder: (context, ref, _) {
          final currentType = _currentType;
          final (keyword, sort) = ref.watch(
            userCollectionsProvider.select(
              (state) {
                final tab = state.tabState(currentType);
                return (tab.keyword, tab.sort);
              },
            ),
          );
          final l10n = AppLocalizations.of(context);
          final theme = Theme.of(context);
          final fabTheme = theme.floatingActionButtonTheme;
          final foreground =
              fabTheme.foregroundColor ?? theme.colorScheme.onPrimaryContainer;
          final label = [
            if (keyword != null && keyword.isNotEmpty) keyword,
            if (sort == CollectionSort.watch) l10n.collectionSortWatch,
          ].join(' · ');

          return JellyMenu<CollectionFilterResult?>(
            key: ValueKey((widget.user.id, currentType)),
            tooltip: l10n.filterCollection,
            preferredVerticalDirection: VerticalDirection.up,
            elevation: fabTheme.elevation ?? 6,
            triggerResizeDuration: const Duration(milliseconds: 220),
            triggerColor:
                fabTheme.backgroundColor ?? theme.colorScheme.primaryContainer,
            trigger: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tune, color: foreground),
                    if (label.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            label,
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: foreground),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            menuBuilder: (context, select) => CollectionFilterForm(
              initialKeyword: keyword ?? '',
              initialSort: AppSettings.getCollectionSort(currentType),
              onSubmit: select,
              onCancel: () => select(null),
            ),
            onSelected: (filters) {
              if (filters == null) return;
              ref.read(userCollectionsProvider.notifier).applyFilters(
                    currentType,
                    keyword: filters.keyword,
                    sort: filters.sort,
                  );
            },
          );
        },
      ),
    );
  }

  Widget _buildCollectionTabLabel(BuildContext context, String label) {
    final colors = Theme.of(context).colorScheme;
    final parts = label.split('\n');
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        Text(parts.first, maxLines: 1, overflow: TextOverflow.ellipsis),
        DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.onSurfaceVariant.withValues(alpha: 0.12),
            shape: const StadiumBorder(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              parts.length > 1 ? parts[1] : '0',
              maxLines: 1,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarTitle(BuildContext context, bool isPinned) {
    final user = widget.user;
    final currentType = _currentType;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: 5,
        children: [
          AnimatedOpacity(
            opacity: isPinned ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: ExcludeSemantics(
              excluding: !isPinned,
              child: _buildUserPill(context, user),
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
            opacity: !isPinned ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: ExcludeSemantics(
              excluding: isPinned,
              child: GlassCapsule(
                child: SizedBox.square(
                  dimension: 40,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _showUserInfo,
                    builder: (context, showUserInfo, _) => IconButton(
                      onPressed: () =>
                          _showUserInfo.value = !_showUserInfo.value,
                      tooltip:
                          showUserInfo ? l10n.showUserInfo : l10n.hideUserInfo,
                      icon: Icon(
                        showUserInfo ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (SystemUtil.isDesktop)
            GlassCapsule(
              child: SizedBox.square(
                dimension: 40,
                child: Consumer(
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
              ),
            ),
          GlassCapsule(
            color: Colors.transparent,
            child: JellyMenu<_LoginOverflowAction>(
              tooltip: l10n.moreMenu,
              triggerColor:
                  GlassCapsule.surfaceColor(Theme.of(context).colorScheme),
              preferredVerticalDirection: VerticalDirection.down,
              trigger: SizedBox.square(
                dimension: 40,
                child: Icon(
                  Icons.notes_outlined,
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              menuBuilder: (context, select) {
                final theme = Theme.of(context);
                final style = TextButton.styleFrom(
                  alignment: AlignmentDirectional.centerStart,
                  foregroundColor: theme.colorScheme.onSurface,
                  textStyle: theme.textTheme.bodyLarge,
                  padding: JellyMenu.itemPadding(context),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final action in _LoginOverflowAction.values)
                          TextButton(
                            style: style,
                            onPressed: () => select(action),
                            child: Row(
                              children: [
                                Icon(action.icon, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    action.label(l10n),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              onSelected: (action) {
                switch (action) {
                  case _LoginOverflowAction.favoriteWallpapers:
                    appNavigatorOf(context).openFavoriteWallpapers<void>();
                  case _LoginOverflowAction.settings:
                    appNavigatorOf(context).openSettings<void>(
                        destination: SettingsDestination.menu);
                  case _LoginOverflowAction.playRecord:
                    appNavigatorOf(context).openPlayRecord<void>();
                  case _LoginOverflowAction.downloads:
                    appNavigatorOf(context).openDownload<void>();
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
          ),
        ],
      ),
    );
  }

  Widget _buildUserPill(BuildContext context, FlowUsers user) {
    final colors = Theme.of(context).colorScheme;
    return GlassCapsule(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(5, 5, 12, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            ClipOval(
              child: user.avatar != null && user.avatar!.isNotEmpty
                  ? AnimationNetworkImage(
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                      gaplessResize: true,
                      url: user.avatar!,
                    )
                  : Icon(Icons.person,
                      size: 30, color: colors.onSurfaceVariant),
            ),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nickname.isNotEmpty ? user.nickname : user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    FormatTimeUtil.formatDate(user.createTime),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                child: ImageFiltered(
                  enabled: blurSigma > 0,
                  imageFilter:
                      ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
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
                      gaplessResize: true,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: ValueListenableBuilder<bool>(
            valueListenable: _showUserInfo,
            builder: (context, showUserInfo, child) =>
                showUserInfo ? child! : const SizedBox.shrink(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasAvatar)
                  AnimationNetworkImage(
                    borderRadius: BorderRadius.circular(100),
                    url: user.avatar!,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                    gaplessResize: true,
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
          ),
        ),
      ],
    );
  }
}
