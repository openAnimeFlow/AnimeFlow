import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/pages/search/search_details_content.dart';
import 'package:anime_flow/pages/search/search_omitted_content.dart';
import 'package:anime_flow/stores/search/search_history_manager.dart';
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
  bool _isSearching = false;
  SubjectItem? searchItem;
  bool _isDetailsContent = true;
  List<String> _searchHistory = [];
  String _currentKeyword = '';
  int _offset = 0;
  final int _limit = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
      _loadSearchHistory();
    });

    // 监听滚动，触发加载更多
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  // 加载搜索历史
  void _loadSearchHistory() async {
    final history = await searchHistoryManager.getSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  void _onSearch(String query, {bool loadMore = false}) async {
    if (query.isEmpty) return;

    // 如果是首次搜索，保存搜索记录
    if (!loadMore) {
      await searchHistoryManager.saveSearchHistory(query);
      _loadSearchHistory();
    }

    // 如果正在加载，则不再加载
    if (_isSearching) return;

    // 如果是加载更多，但没有更多数据，则不加载
    if (loadMore && !_hasMore) return;

    setState(() {
      _isSearching = true;
      if (!loadMore) {
        _currentKeyword = query;
        _offset = 0;
        _hasMore = true;
      }
    });

    try {
      final offset = loadMore ? _offset : 0;
      final value = await BgmRequest.searchSubjectService(
        keyword: _currentKeyword,
        limit: _limit,
        offset: offset,
      );
      if (mounted) {
        setState(() {
          if (loadMore && searchItem != null) {
            // 追加数据
            searchItem = SubjectItem(
              data: [...searchItem!.data, ...value.data],
              total: value.total,
            );
          } else {
            // 首次加载
            searchItem = value;
          }
          _offset = offset + value.data.length;
          _hasMore = value.data.length == _limit &&
              searchItem!.data.length < value.total;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // 加载更多
  void _loadMore() {
    if (_currentKeyword.isNotEmpty && !_isSearching && _hasMore) {
      _onSearch(_currentKeyword, loadMore: true);
    }
  }

  // 清除搜索历史
  void _clearSearchHistory() async {
    await searchHistoryManager.clearSearchHistory();
    _loadSearchHistory();
  }

  // 删除单个搜索历史项
  void _removeSearchHistoryItem(String keyword) async {
    await searchHistoryManager.removeSearchHistoryItem(keyword);
    _loadSearchHistory();
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
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
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
                  _currentKeyword = '';
                  _offset = 0;
                  _hasMore = true;
                });
              },
              topPadding: topPadding,
            ),
          ),
          if (_isSearching && searchItem == null)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (searchItem == null)
            _buildSearchHistory()
          else ...[
            // 搜索结果列表
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxWidth),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '搜索到 ${searchItem!.total} 条内容',
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
                        itemCount: searchItem!.data.length + 1,
                        itemBuilder: (context, index) {
                          // 如果是最后一项，显示加载指示器或"没有更多了"
                          if (index == searchItem!.data.length) {
                            return _hasMore
                                ? _isSearching
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : const SizedBox.shrink()
                                : const Center(
                                    child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text("没有更多了"),
                                  ));
                          }

                          final searchData = searchItem!.data[index];
                          return _isDetailsContent
                              ? SearchDetailsContentView(
                                  searchData: searchData,
                                  itemHeight: detailsItemHeight)
                              : SearchOmittedContent(searchData: searchData);
                        },
                      ),
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
                            _searchController.text = keyword;
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
