import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/user_collections_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/pages/user_space/user_stores.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/utils/layout_util.dart';
import 'package:anime_flow/widget/subject_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///空间收藏页面
class CollectView extends StatefulWidget {
  const CollectView({super.key});

  @override
  State<CollectView> createState() => _CollectViewState();
}

class _CollectViewState extends State<CollectView>
    with AutomaticKeepAliveClientMixin {
  late UserSpaceStores userSpaceStores;
  UserCollectionsItem? userCollections;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int _selectedCollectionType = 3;
  final Map<int, UserCollectionsItem?> _collectionCache = {}; // 每个收藏类型的缓存

  List<String> get _tabs {
    const Map<int, String> collectionTypes = {
      1: '想看',
      2: '看过',
      3: '在看',
      4: '搁置',
      5: '抛弃',
    };
    final stats = userSpaceStores.userInfo.value.stats.subject.two;
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
    userSpaceStores = Get.find<UserSpaceStores>();
    _queryUserCollection();
  }

  @override
  bool get wantKeepAlive => true;

  /// 滚动监听
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
        // 距离底部200像素时加载更多
        _loadMore();
      }
    }
    return false; // 返回 false 让通知继续向上传递，这样外层 NestedScrollView 也能接收到滚动事件
  }

  ///查询用户收藏
  void _queryUserCollection(
      {int? collectionType, bool loadMore = false}) async {
    final type = collectionType ?? _selectedCollectionType;

    // 如果是切换类型，先检查缓存
    if (!loadMore &&
        _collectionCache.containsKey(type) &&
        _collectionCache[type] != null) {
      if (mounted) {
        setState(() {
          _selectedCollectionType = type;
          userCollections = _collectionCache[type];
          isLoading = false;
          hasMore = (userCollections!.data.length < userCollections!.total);
        });
      }
      return;
    }

    // 如果没有缓存，发起请求
    if (mounted) {
      setState(() {
        if (loadMore) {
          isLoadingMore = true;
        } else {
          isLoading = true;
          _selectedCollectionType = type;
        }
      });
    }

    try {
      final userInfo = userSpaceStores.userInfo.value;
      final currentOffset = loadMore && userCollections != null
          ? userCollections!.data.length
          : 0;

      final newCollections = await UserRequest.queryUserCollectionService(
          userInfo.username,
          type: type,
          limit: 20,
          offset: currentOffset);

      if (mounted) {
        setState(() {
          if (loadMore && userCollections != null) {
            // 加载更多：合并数据
            final mergedData = [
              ...userCollections!.data,
              ...newCollections.data,
            ];
            userCollections = UserCollectionsItem(
              data: mergedData,
              total: newCollections.total,
            );
          } else {
            // 首次加载或切换类型
            userCollections = newCollections;
          }

          // 更新缓存
          _collectionCache[type] = userCollections;

          // 判断是否还有更多数据
          hasMore = userCollections!.data.length < userCollections!.total;

          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      // 请求失败时，如果缓存中有数据，使用缓存数据
      if (_collectionCache.containsKey(type) &&
          _collectionCache[type] != null) {
        if (mounted) {
          setState(() {
            if (!loadMore) {
              userCollections = _collectionCache[type];
            }
            isLoading = false;
            isLoadingMore = false;
            hasMore = (userCollections?.data.length ?? 0) <
                (userCollections?.total ?? 0);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            isLoadingMore = false;
          });
        }
      }
    }
  }

  /// 加载更多
  void _loadMore() {
    if (!isLoadingMore && hasMore && userCollections != null) {
      _queryUserCollection(loadMore: true);
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
    final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverOverlapInjector(handle: handle),
          SliverPadding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: List.generate(_tabs.length, (index) {
                    final tab = _tabs[index];
                    final parts = tab.split('\n');
                    final collectionType = index + 1;
                    final isSelected =
                        _selectedCollectionType == collectionType;
                    final textStyle = TextStyle(
                        fontSize: _fontSize, fontWeight: FontWeight.w600);
                    return InkWell(
                      onTap: () {
                        _queryUserCollection(collectionType: collectionType);
                      },
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
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
                  }),
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
                  left: 8,
                  right: 8,
                  bottom: MediaQuery.of(context).padding.bottom),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: LayoutUtil.getCrossAxisCount(context),
                  childAspectRatio: 0.7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final collection = userCollections!.data[index];
                    return InkWell(
                      onTap: () {
                        final subject = SubjectBasicData(
                            id: collection.id,
                            name: collection.nameCN ?? collection.name,
                            image: collection.images.large);
                        Get.toNamed(RouteName.animeInfo, arguments: subject);
                      },
                      child: SubjectCard(
                        image: collection.images.large,
                        title: collection.nameCN ?? collection.name,
                      ),
                    );
                  },
                  childCount: userCollections!.data.length,
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
