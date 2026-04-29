import 'package:anime_flow/pages/search/search_controller.dart'
    as search_page_controller;
import 'package:anime_flow/pages/search/search_details_content.dart';
import 'package:anime_flow/pages/search/search_omitted_content.dart';
import 'package:anime_flow/stores/search/search_history_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// 搜索页
class SearchPage extends StatefulWidget {
  final String? keywords;

  const SearchPage({super.key, this.keywords});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode searchFocusNode = FocusNode();
  final search_page_controller.SearchController _searchStateController =
      Get.put(search_page_controller.SearchController());
  bool _isDetailsContent = true;
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(searchFocusNode);
      _loadSearchHistory();
      final routeKeywords =
          GoRouterState.of(context).uri.queryParameters['keywords'];
      final keywords = (widget.keywords ?? routeKeywords)?.trim();
      if (keywords != null && keywords.isNotEmpty) {
        searchController.text = keywords;
        _onSearch(keywords);
      }
    });

    // 监听滚动，触发加载更多
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        _searchStateController.loadMore();
      }
    });
  }

  // 加载搜索历史
  Future<void> _loadSearchHistory() async {
    final history = await searchHistoryManager.getSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _onSearch(String query) {
    return _searchStateController.search(
      query,
      onHistoryChanged: _loadSearchHistory,
    );
  }

  // 清除搜索历史
  void _clearSearchHistory() async {
    await searchHistoryManager.clearSearchHistory();
    await _loadSearchHistory();
  }

  // 删除单个搜索历史项
  void _removeSearchHistoryItem(String keyword) async {
    await searchHistoryManager.removeSearchHistoryItem(keyword);
    await _loadSearchHistory();
  }

  // 详情视图列数
  int _calculateDetailsCount(double screenWidth) {
    const minItemWidth = 320.0;
    if (screenWidth < 450) return 1;
    return (screenWidth / minItemWidth).floor().clamp(1, 4);
  }

  // 简洁视图列数
  int _calculateOmittedCount(double screenWidth) {
    const minItemWidth = 200.0; // 海报宽度
    return (screenWidth / minItemWidth).floor().clamp(3, 6);
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    searchFocusNode.dispose();
    Get.delete<search_page_controller.SearchController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width - 32; // 减去左右 padding
    const maxWidth = 1400.0;

    // 根据视图类型计算列数
    final effectiveWidth = screenWidth.clamp(0.0, maxWidth - 32);
    final crossAxisCount = _isDetailsContent
        ? _calculateDetailsCount(screenWidth)
        : _calculateOmittedCount(effectiveWidth);
    const double detailsItemHeight = 160.0;

    return Scaffold(
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          // 可折叠的 AppBar + 吸顶搜索框
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySearchHeaderDelegate(
              searchController: searchController,
              focusNode: searchFocusNode,
              onSearch: _onSearch,
              maxWidth: maxWidth,
              onClear: () {
                _searchStateController.clearResults();
              },
              topPadding: topPadding,
            ),
          ),
          Obx(() {
            final searchItem = _searchStateController.searchResults.value;
            final isSearching = _searchStateController.isSearching.value;
            final hasMore = _searchStateController.hasMore.value;

            if (isSearching && searchItem == null) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (searchItem == null) {
              return _buildSearchHistory();
            }

            return SliverMainAxisGroup(
              slivers: [
                // 搜索结果列表
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: maxWidth),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '搜索到 ${searchItem.total} 条内容',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    _isDetailsContent = !_isDetailsContent;
                                  });
                                },
                                icon: Icon(
                                  _isDetailsContent
                                      ? Icons.image_outlined
                                      : Icons.art_track_rounded,
                                  size: 35,
                                ))
                          ]),
                    ),
                  ),
                ),
                // 搜索结果列表
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: maxWidth),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          child: GridView.builder(
                            key: ValueKey(_isDetailsContent),
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: _isDetailsContent
                                ? SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    mainAxisExtent: detailsItemHeight,
                                  )
                                : SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 2 / 3,
                                  ),
                            itemCount: searchItem.data.length + 1,
                            itemBuilder: (context, index) {
                              // 如果是最后一项，显示加载指示器或"没有更多了"
                              if (index == searchItem.data.length) {
                                return hasMore
                                    ? isSearching
                                        ? const Center(
                                            child: CircularProgressIndicator())
                                        : const SizedBox.shrink()
                                    : const Center(
                                        child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text("没有更多了"),
                                      ));
                              }

                              final searchData = searchItem.data[index];
                              return _isDetailsContent
                                  ? SearchDetailsContentView(
                                      searchData: searchData,
                                      itemHeight: detailsItemHeight)
                                  : SearchOmittedContent(
                                      searchData: searchData);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          })
        ],
      ),
    );
  }

  // 搜索历史
  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 80,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                '输入关键词开始搜索',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        // 标题和清除按钮
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '搜索历史',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _clearSearchHistory,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('清除全部'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 历史列表
        SliverPadding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  children: List.generate(
                    _searchHistory.length,
                    (index) {
                      final keyword = _searchHistory[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(keyword),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => _removeSearchHistoryItem(keyword),
                            tooltip: '删除',
                          ),
                          onTap: () {
                            searchController.text = keyword;
                            _onSearch(keyword);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 吸顶搜索 Header Delegate（包含 AppBar 和搜索框）
class _StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final FocusNode focusNode;
  final Function(String) onSearch;
  final VoidCallback onClear;
  final double topPadding;
  final double maxWidth;

  // AppBar 高度
  static const double _appBarHeight = 56;

  // 搜索框区域高度
  static const double _searchBarHeight = 64;

  _StickySearchHeaderDelegate({
    required this.searchController,
    required this.focusNode,
    required this.onSearch,
    required this.onClear,
    required this.topPadding,
    required this.maxWidth,
  });

  @override
  double get minExtent => _searchBarHeight + topPadding;

  @override
  double get maxExtent => _appBarHeight + _searchBarHeight + topPadding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // 计算 AppBar 的显示比例 (1.0 完全显示, 0.0 完全隐藏)
    final appBarVisibility = (1 - shrinkOffset / _appBarHeight).clamp(0.0, 1.0);
    final isCollapsed = appBarVisibility < 0.5;

    return Container(
      height: maxExtent - shrinkOffset.clamp(0.0, _appBarHeight),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: isCollapsed
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // 顶部安全区域
          SizedBox(height: topPadding),
          // AppBar（可折叠）
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: appBarVisibility,
              child: Opacity(
                opacity: appBarVisibility,
                child: SizedBox(
                  height: _appBarHeight,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Get.back(),
                      ),
                      const Expanded(
                        child: Text(
                          '搜索',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 搜索框
          Expanded(
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: searchController,
                    builder: (context, value, child) {
                      return TextField(
                        scrollPadding:
                            const EdgeInsets.symmetric(horizontal: 50),
                        controller: searchController,
                        focusNode: focusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: onSearch,
                        onChanged: (text) {
                          if (text.isEmpty) {
                            onClear();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: '搜索动漫...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                    onClear();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      );
                    },
                  ),
                )),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchHeaderDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding;
  }
}
