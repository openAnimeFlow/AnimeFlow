import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/features/user_space/presentation/providers/space_collections_provider.dart';
import 'package:anime_flow/shared/navigation/args/info_route_extra.dart';
import 'package:anime_flow/features/user_space/presentation/providers/user_space_provider.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/core/utils/layout_util.dart';
import 'package:anime_flow/shared/widgets/subject_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///空间收藏页面
class CollectView extends ConsumerStatefulWidget {
  final String username;

  const CollectView({super.key, required this.username});

  @override
  ConsumerState<CollectView> createState() => _CollectViewState();
}

class _CollectViewState extends ConsumerState<CollectView>
    with AutomaticKeepAliveClientMixin {
  int _selectedCollectionType = 3;

  List<String> get _tabs {
    const Map<int, String> collectionTypes = {
      1: '想看',
      2: '看过',
      3: '在看',
      4: '搁置',
      5: '抛弃',
    };
    final stats = ref
        .watch(userSpaceProvider(widget.username))
        .requireValue
        .stats
        .subject
        .two;
    return [
      '${collectionTypes[1]}\n${stats.one}',
      '${collectionTypes[2]}\n${stats.two}',
      '${collectionTypes[3]}\n${stats.three}',
      '${collectionTypes[4]}\n${stats.four}',
      '${collectionTypes[5]}\n${stats.five}',
    ];
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) _queryUserCollection();
    });
  }

  @override
  bool get wantKeepAlive => true;

  /// 滚动监听
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
        // 距离底部200像素时加载更多
        ref
            .read(spaceCollectionsProvider(widget.username).notifier)
            .loadMore(_selectedCollectionType);
      }
    }
    return false; // 返回 false 让通知继续向上传递，这样外层 NestedScrollView 也能接收到滚动事件
  }

  /// 标签选择只负责展示；请求、分页与缓存由 Provider 管理。
  void _queryUserCollection({int? collectionType}) {
    final type = collectionType ?? _selectedCollectionType;
    if (type != _selectedCollectionType) {
      setState(() => _selectedCollectionType = type);
    }
    ref
        .read(spaceCollectionsProvider(widget.username).notifier)
        .loadInitial(type);
  }

  @override
  void didUpdateWidget(covariant CollectView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) {
      Future.microtask(() {
        if (mounted) _queryUserCollection();
      });
    }
  }

  ///字体大小
  double get _fontSize {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 12;
    } else if (width < 800) {
      return 15;
    } else {
      return 18;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final result = ref.watch(
        spaceCollectionsProvider(widget.username))[_selectedCollectionType];
    final userCollections = result?.data;
    final isLoading =
        result == null || result.isLoading && userCollections == null;
    final isLoadingMore = result?.isLoading == true && userCollections != null;
    final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverOverlapInjector(handle: handle),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: LayoutConstant.maxWidth),
                  child: SizedBox(
                    height: _fontSize + 12,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tabs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 5),
                      itemBuilder: (context, index) {
                        final tab = _tabs[index];
                        final parts = tab.split('\n');
                        final collectionType = index + 1;
                        final isSelected =
                            _selectedCollectionType == collectionType;
                        final textStyle = TextStyle(
                            fontSize: _fontSize, fontWeight: FontWeight.w600);
                        return InkWell(
                          onTap: () {
                            _queryUserCollection(
                                collectionType: collectionType);
                          },
                          borderRadius: BorderRadius.circular(5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  parts[0],
                                  style: textStyle.copyWith(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : null,
                                  ),
                                ),
                                Text(
                                  parts[1],
                                  style: textStyle.copyWith(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : null,
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (userCollections == null)
            const SliverFillRemaining(
              child: Center(child: Text('没有收藏')),
            )
          else
            SliverPadding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: LayoutConstant.maxWidth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: LayoutUtil.getCrossAxisCount(context),
                          childAspectRatio: 0.7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: userCollections.data.length,
                        itemBuilder: (context, index) {
                          final collection = userCollections.data[index];
                          return InkWell(
                            onTap: () {
                              final subject = InfoRouteExtra(
                                  id: collection.id,
                                  name: collection.nameCN ?? collection.name,
                                  image: collection.images.large);
                              appNavigatorOf(context)
                                  .openAnimeInfoFromExtra<void>(
                                      context, subject);
                            },
                            child: SubjectCard(
                              image: collection.images.large,
                              title: collection.nameCN ?? collection.name,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
