import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  // 模拟搜索结果数据
  final List<String> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    // TODO: 实现实际的搜索逻辑
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchResults.clear();
          // 模拟搜索结果
          for (int i = 0; i < 30; i++) {
            _searchResults.add('搜索结果 $i: $query');
          }
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

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
              topPadding: topPadding,
            ),
          ),
          // 搜索结果列表
          if (_isSearching)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_searchResults.isEmpty)
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
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return ListTile(
                    leading: Container(
                      width: 60,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.movie_outlined,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    title: Text(_searchResults[index]),
                    subtitle: const Text('动漫简介'),
                    onTap: () {
                      // TODO: 跳转到详情页
                    },
                  );
                },
                childCount: _searchResults.length,
              ),
            ),
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
  final double topPadding;

  // AppBar 高度
  static const double _appBarHeight = 56;

  // 搜索框区域高度
  static const double _searchBarHeight = 64;

  _StickySearchHeaderDelegate({
    required this.searchController,
    required this.focusNode,
    required this.onSearch,
    required this.topPadding,
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
                  constraints: const BoxConstraints(maxWidth: 1200),
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
