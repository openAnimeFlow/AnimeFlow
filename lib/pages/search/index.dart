import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/search_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'search_content.dart';

/// 搜索页
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  SearchItem? searchItem;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });
    try {
      final value = await BgmRequest.searchSubjectService(
        keyword: query,
        limit: 10,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          searchItem = value;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // 计算网格列数：手机端 1 列，宽屏多列
  int _calculateCrossAxisCount(double screenWidth) {
    const minItemWidth = 320.0; // 每个项目最小宽度
    if (screenWidth < 450) return 1; // 手机端固定 1 列
    return (screenWidth / minItemWidth).floor().clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width - 32; // 减去左右 padding
    final crossAxisCount = _calculateCrossAxisCount(screenWidth);
    const maxWidth = 1400.0;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 可折叠的 AppBar + 吸顶搜索框
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySearchHeaderDelegate(
              searchController: _searchController,
              focusNode: _searchFocusNode,
              onSearch: _onSearch,
              maxWidth: maxWidth,
              onClear: () {
                setState(() {
                  searchItem = null;
                });
              },
              topPadding: topPadding,
            ),
          ),
          // 搜索结果列表
          if (_isSearching)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (searchItem == null)
            SliverFillRemaining(
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
            )
          else ...[
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '搜索到 ${searchItem!.data.length} 条内容',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 搜索结果列表
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: SearchContentView.itemHeight,
                      ),
                      itemCount: searchItem!.data.length,
                      itemBuilder: (context, index) {
                        final searchData = searchItem!.data[index];
                        return SearchContentView(searchData: searchData);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
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
    required this.topPadding, required this.maxWidth,
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
                  child: TextField(
                    controller: searchController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: '搜索动漫...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                onClear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSearch,
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
