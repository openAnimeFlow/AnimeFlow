import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/enums/sort_type.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/utils/layout_util.dart';
import 'package:anime_flow/widget/subject_carf.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  SubjectItem? subject;
  Logger logger = Logger();

  // 下拉菜单状态
  SortType _selectedSort = SortType.rank;
  int? _selectedYear;
  int? _selectedMonth;

  // 分页状态
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  // 滚动控制
  late ScrollController _scrollController;
  bool _showBackToTop = false;

  // 年份列表（从当前年份往前推20年）
  List<int> get _years {
    final currentYear = DateTime.now().year;
    return List.generate(20, (index) => currentYear - index);
  }

  // 月份列表
  List<int> get _months => List.generate(12, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _getRanking();
  }

  void _scrollListener() {
    // 当滚动超过 300px 时显示返回顶部按钮
    if (_scrollController.offset >= 300) {
      if (!_showBackToTop) {
        setState(() {
          _showBackToTop = true;
        });
      }
    } else {
      if (_showBackToTop) {
        setState(() {
          _showBackToTop = false;
        });
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _getRanking({bool loadMore = false}) async {
    // 如果是加载更多，检查是否正在加载或没有更多数据
    if (loadMore) {
      if (_isLoading || !_hasMore) {
        return;
      }
    } else {
      // 如果不是加载更多，重置状态
      _currentPage = 0;
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      final response = await BgmRequest.rankService(
          page: page,
          sort: _selectedSort,
          year: _selectedYear,
          month: _selectedMonth);

      if (mounted) {
        setState(() {
          if (loadMore && subject != null) {
            // 追加数据
            subject!.data.addAll(response.data);
          } else {
            // 首次加载或刷新
            subject = response;
          }
          _currentPage = page;
          // 判断是否还有更多数据（假设每页返回固定数量，如果返回数量少于预期则认为没有更多）
          _hasMore = response.data.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('排行榜'),
      ),
      body: RefreshIndicator(
        onRefresh: _getRanking,
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: PlayLayoutConstant.maxWidth),
            child: subject == null
                ? const CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ],
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification) {
                        final metrics = notification.metrics;
                        // 当滚动到距离底部 200px 时，触发加载更多
                        if (metrics.pixels >= metrics.maxScrollExtent - 200 &&
                            subject != null &&
                            subject!.data.isNotEmpty &&
                            !_isLoading &&
                            _hasMore) {
                          _getRanking(loadMore: true);
                        }
                      }
                      return false;
                    },
                    child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverAppBar(
                            pinned: true,
                            floating: true,
                            title: Center(
                              child: Wrap(
                                spacing: 5,
                                children: [
                                  // 排序类型下拉
                                  PopupMenuButton<SortType>(
                                    offset: const Offset(0, 40),
                                    initialValue: _selectedSort,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 3),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.sort, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            _selectedSort.name,
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    itemBuilder: (context) {
                                      return SortType.values.map((type) {
                                        return PopupMenuItem<SortType>(
                                          value: type,
                                          child: Text(type.name),
                                        );
                                      }).toList();
                                    },
                                    onSelected: (value) {
                                      setState(() {
                                        _selectedSort = value;
                                      });
                                      _getRanking();
                                    },
                                  ),
                                  // 年份下拉
                                  PopupMenuButton<int>(
                                    offset: const Offset(0, 40),
                                    initialValue: _selectedYear ?? -1,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 3),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _selectedYear == null
                                                ? '全部年份'
                                                : '$_selectedYear年',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    itemBuilder: (context) {
                                      return [
                                        const PopupMenuItem<int>(
                                          value: -1,
                                          child: Text('全部'),
                                        ),
                                        ..._years.map((year) {
                                          return PopupMenuItem<int>(
                                            value: year,
                                            child: Text('$year年'),
                                          );
                                        }),
                                      ];
                                    },
                                    onSelected: (value) {
                                      setState(() {
                                        _selectedYear =
                                            value == -1 ? null : value;
                                      });
                                      _getRanking();
                                    },
                                  ),
                                  // 月份下拉
                                  PopupMenuButton<int>(
                                    offset: const Offset(0, 40),
                                    initialValue: _selectedMonth ?? -1,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 3),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _selectedMonth == null
                                                ? '全部月份'
                                                : '$_selectedMonth月',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    itemBuilder: (context) {
                                      return [
                                        const PopupMenuItem<int>(
                                          value: -1,
                                          child: Text('全部'),
                                        ),
                                        ..._months.map((month) {
                                          return PopupMenuItem<int>(
                                            value: month,
                                            child: Text('$month月'),
                                          );
                                        }),
                                      ];
                                    },
                                    onSelected: (value) {
                                      setState(() {
                                        _selectedMonth =
                                            value == -1 ? null : value;
                                      });
                                      _getRanking();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.all(10),
                            sliver: SliverGrid.builder(
                              itemCount:
                                  subject!.data.length + (_hasMore ? 1 : 0),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    LayoutUtil.getCrossAxisCount(context),
                                crossAxisSpacing: 5, // 横向间距
                                mainAxisSpacing: 5, // 纵向间距
                                childAspectRatio: 0.7, // 宽高比
                              ),
                              itemBuilder: (context, index) {
                                // 最后一项显示加载指示器或"到底了"
                                if (index == subject!.data.length) {
                                  return _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text("到底了"),
                                          ),
                                        );
                                }
                                final data = subject!.data[index];
                                return SubjectCarfView(subject: data);
                              },
                            ),
                          )
                        ]),
                  ),
          ),
        ),
      ),
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              child: Icon(Icons.arrow_upward,
                  color: Theme.of(context).colorScheme.primary),
            )
          : null,
    );
  }
}
