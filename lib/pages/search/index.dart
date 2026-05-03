import 'dart:async';

import 'package:anime_flow/pages/search/search_controller.dart';
import 'package:anime_flow/pages/search/search_details_content.dart';
import 'package:anime_flow/pages/search/search_omitted_content.dart';
import 'package:anime_flow/routes/routes.dart';
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
  final SearchPageController searchPageController =
      Get.put(SearchPageController());
  bool _isDetailsContent = true;

  /// 搜索建议防抖用
  Timer? suggestionDebounce;

  @override
  void initState() {
    super.initState();
    searchController.addListener(fetchSearchSuggestions);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(searchFocusNode);
      final routeKeywords =
          GoRouterState.of(context).uri.queryParameters['keywords'];
      final keywords = (widget.keywords ?? routeKeywords)?.trim();
      if (keywords != null && keywords.isNotEmpty) {
        searchController.text = keywords;
        _submitSearch(keywords);
      }
    });

    // 监听滚动，触发加载更多
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        searchPageController.loadMore();
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    searchFocusNode.dispose();
    suggestionDebounce?.cancel();
    Get.delete<SearchPageController>();
    super.dispose();
  }

  /// 搜索建议
  void fetchSearchSuggestions() {
    suggestionDebounce?.cancel();
    final keyword = searchController.text;
    suggestionDebounce = Timer(const Duration(seconds: 2), () {
      if (keyword.trim().isEmpty) {
        searchPageController.clearSearchSuggestions();
        return;
      }
      searchPageController.fetchSearchSuggestions(keyword);
    });
  }

  void _cancelSearchSuggestions() {
    suggestionDebounce?.cancel();
    suggestionDebounce = null;
    searchPageController.clearSearchSuggestions();
  }

  Future<void> _submitSearch(String keyword) async {
    _cancelSearchSuggestions();
    await searchPageController.search(keyword);
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
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            // 可折叠的 AppBar + 吸顶搜索框
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchHeaderDelegate(
                searchController: searchController,
                focusNode: searchFocusNode,
                onSearch: _submitSearch,
                maxWidth: maxWidth,
                onClear: () {
                  searchPageController.clearResults();
                  searchController.clear();
                  _cancelSearchSuggestions();
                },
                topPadding: topPadding,
              ),
            ),
            Obx(() {
              final searchItem = searchPageController.searchResults.value;
              final isSearching = searchPageController.isSearching.value;
              final hasMore = searchPageController.hasMore.value;
              final searchSuggestions = searchPageController.searchSuggestions;
              if (isSearching && searchItem == null) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (searchItem == null) {
                if (searchSuggestions.isNotEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: maxWidth),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '搜索建议',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (var suggestion in searchSuggestions)
                                ListTile(
                                  title: Text(suggestion),
                                  onTap: () {
                                    searchController.text = suggestion;
                                    unawaited(_submitSearch(suggestion));
                                  },
                                )
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return _buildSearchHistory();
              }

              return SliverMainAxisGroup(
                slivers: [
                  // 搜索结果列表
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: Center(
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
                      )),
                    ),
                  ),
                  // 搜索结果列表
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: maxWidth),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          child: GridView.builder(
                            key: ValueKey(_isDetailsContent),
                            padding: EdgeInsets.only(
                                left: 10,
                                right: 10,
                                bottom: MediaQuery.of(context).padding.bottom),
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
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
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
                ],
              );
            })
          ],
        ),
      ),
    );
  }

  // 搜索历史
  Widget _buildSearchHistory() {
    return Obx(() {
      final searchHistory = searchPageController.searchHistory;
      if (searchHistory.isEmpty) {
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
      } else {
        return SliverMainAxisGroup(
          slivers: [
            // 标题和清除按钮
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
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
                          onPressed: () => searchPageController
                              .searchHistoryManager
                              .clearAllHistory(),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('清除全部'),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
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
                        searchHistory.length,
                        (index) {
                          final history = searchHistory[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.history),
                              title: Text(history.keyword),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () => searchPageController
                                    .searchHistoryManager
                                    .removeSearchHistory(history.keyword),
                                tooltip: '删除',
                              ),
                              onTap: () {
                                searchController.text = history.keyword;
                                searchPageController.search(history.keyword);
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
    });
  }
}

/// 吸顶搜索 Header Delegate（包含 AppBar 和搜索框）
class _StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final FocusNode focusNode;
  final Future<void> Function(String) onSearch;
  final VoidCallback onClear;
  final double topPadding;
  final double maxWidth;

  // AppBar 高度
  static const double _appBarHeight = 60;

  // 搜索框区域高度
  static const double _searchBarHeight = 64;
  static const double _horizontalPadding = 16;
  static const double _collapsedSearchLeft = 104;

  _StickySearchHeaderDelegate({
    required this.searchController,
    required this.focusNode,
    required this.onSearch,
    required this.onClear,
    required this.topPadding,
    required this.maxWidth,
  });

  @override
  double get minExtent => _appBarHeight + topPadding;

  @override
  double get maxExtent => _appBarHeight + _searchBarHeight + topPadding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapseProgress =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final isCollapsed = collapseProgress > 0.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalInset =
            ((constraints.maxWidth - maxWidth) / 2).clamp(0.0, double.infinity);
        final expandedLeft = horizontalInset + _horizontalPadding;
        final expandedRight = horizontalInset + _horizontalPadding;
        final collapsedLeft = horizontalInset + _collapsedSearchLeft;
        final searchLeft =
            expandedLeft + (collapsedLeft - expandedLeft) * collapseProgress;
        final searchTop =
            topPadding + _appBarHeight + 8 - (_appBarHeight * collapseProgress);

        return Container(
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
          child: Stack(
            children: [
              Positioned(
                top: topPadding,
                left: 0,
                right: 0,
                height: _appBarHeight,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Get.back(),
                    ),
                    const Text(
                      '搜索',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: searchTop,
                left: searchLeft,
                right: expandedRight,
                height: _searchBarHeight - 16,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (context, value, child) {
                    return TextField(
                      scrollPadding: const EdgeInsets.symmetric(horizontal: 50),
                      controller: searchController,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (keyword) {
                        unawaited(onSearch(keyword));
                      },
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  onClear();
                                },
                              )
                            : IconButton(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                onPressed: () async {
                                  final keyword =
                                      await context.push(RouteName.imageSearch);
                                  if (keyword != null && keyword is String) {
                                    searchController.text = keyword;
                                    await onSearch(keyword);
                                  }
                                },
                                icon: const Icon(Icons.image_search_outlined),
                              ),
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
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchHeaderDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding ||
        oldDelegate.maxWidth != maxWidth ||
        oldDelegate.searchController != searchController ||
        oldDelegate.focusNode != focusNode;
  }
}
