import 'package:animation_network_image/animation_network_image.dart';
import 'package:anime_flow/models/item/collections_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/routes/index.dart';
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
    // 延迟加载，确保 token 已经在拦截器中设置好
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.collectionsItem == null && !widget.isLoading && !_hasTriggeredLoad) {
        _hasTriggeredLoad = true;
        widget.onLoad();
      }
    });
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

    return CustomScrollView(
      slivers: <Widget>[
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = widget.collectionsItem!.data[index];
                final subjectBasicData = SubjectBasicData(
                  id: item.id,
                  name: item.nameCN.isEmpty ? item.name : item.nameCN,
                  image: item.images.large,
                );
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Get.toNamed(RouteName.animeDetail,
                          arguments: subjectBasicData);
                    },
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AnimationNetworkImage(
                          url: item.images.medium,
                          width: 60,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        item.nameCN.isEmpty ? item.name : item.nameCN,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.summary.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                item.summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          if (item.rating.score > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.rating.score}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                );
              },
              childCount: widget.collectionsItem!.data.length,
            ),
          ),
        ),
      ],
    );
  }
}
