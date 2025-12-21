import 'package:animation_network_image/animation_network_image.dart';
import 'package:anime_flow/models/item/collections_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/widget/ranking.dart';
import 'package:anime_flow/widget/star.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CollectionTabView extends StatelessWidget {
  final TabController tabController;
  final List<String> tabs;
  final Function(int) onLoad;
  final Set<int> loadingTypes;
  final Map<int, CollectionsItem?> collectionsCache;

  const CollectionTabView(
      {super.key,
      required this.collectionsCache,
      required this.tabController,
      required this.tabs,
      required this.onLoad,
      required this.loadingTypes});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
        controller: tabController,
        children: List.generate(tabs.length, (tabIndex) {
          final type = tabIndex + 1;
          return _CollectionTabView(
            key: PageStorageKey<int>(type),
            type: type,
            collectionsItem: collectionsCache[type],
            isLoading: loadingTypes.contains(type),
            onLoad: () => onLoad(type),
          );
        }));
  }
}

class _CollectionTabView extends StatefulWidget {
  final int type;
  final CollectionsItem? collectionsItem;
  final bool isLoading;
  final VoidCallback onLoad;

  const _CollectionTabView({
    super.key,
    required this.type,
    required this.collectionsItem,
    required this.isLoading,
    required this.onLoad,
  });

  @override
  State<_CollectionTabView> createState() => __CollectionTabViewState();
}

class __CollectionTabViewState extends State<_CollectionTabView> {
  bool _hasTriggeredLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.collectionsItem == null &&
          !widget.isLoading &&
          !_hasTriggeredLoad) {
        _hasTriggeredLoad = true;
        widget.onLoad();
      }
    });
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // 手机端（宽度 < 600）显示 1 列，宽屏显示多列
    if (width < 600) {
      return 1;
    } else if (width < 900) {
      return 2;
    } else if (width < 1200) {
      return 3;
    } else {
      return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || widget.collectionsItem == null) {
      return CustomScrollView(
        slivers: <Widget>[
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (widget.collectionsItem!.data.isEmpty) {
      return CustomScrollView(
        slivers: <Widget>[
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          const SliverFillRemaining(
            child: Center(
              child: Text('暂无数据'),
            ),
          ),
        ],
      );
    }

    final crossAxisCount = _calculateCrossAxisCount(context);
    final collections = widget.collectionsItem!.data;
    return CustomScrollView(
      slivers: <Widget>[
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              // 横向布局，宽高比应该大于 1
              childAspectRatio: 2.5,
            ),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              final subjectBasicData = SubjectBasicData(
                id: collection.id,
                name: collection.nameCN.isEmpty
                    ? collection.name
                    : collection.nameCN,
                image: collection.images.large,
              );
              return Card(
                clipBehavior: Clip.hardEdge,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Get.toNamed(RouteName.animeDetail,
                        arguments: subjectBasicData);
                  },
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左侧封面
                        ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(12)),
                          child: SizedBox(
                            width: 100,
                            child: AnimationNetworkImage(
                              url: collection.images.large,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // 右侧信息
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  collection.nameCN.isEmpty
                                      ? collection.name
                                      : collection.nameCN,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (collection.summary.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    collection.summary,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const Spacer(),
                                Row(
                                  children: [
                                    RankingView(
                                        ranking: collection.rating.rank),
                                    if (collection.rating.score > 0) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          StarView(
                                              iconSize: 16,
                                              score: collection.rating.score),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${collection.rating.score}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
