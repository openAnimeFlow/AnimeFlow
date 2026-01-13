import 'package:flutter/material.dart';
import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/pages/recommend/anime/calendar.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/utils/layout_util.dart';
import 'package:anime_flow/widget/subject_carf.dart';
import 'package:anime_flow/models/item/bangumi/hot_item.dart';
import 'package:anime_flow/models/item/bangumi/calendar_item.dart';
import 'package:logger/logger.dart';

class AnimePage extends StatefulWidget {
  final ValueChanged<bool>? onShowBackToTopChanged;
  final ValueChanged<VoidCallback>? onScrollToTopCallback;

  const AnimePage({
    super.key,
    this.onShowBackToTopChanged,
    this.onScrollToTopCallback,
  });

  @override
  State<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage>  with AutomaticKeepAliveClientMixin{
  final List<Data> _dataList = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  final _scrollController = ScrollController();
  Calendar? _calendar;
  bool _isCalendarLoading = false;

  static const _contentPadding = EdgeInsets.all(10);

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchCalendar();
    _scrollController.addListener(_scrollListener);
    // 将 scrollToTop 方法传递给父组件
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onScrollToTopCallback != null && mounted) {
        widget.onScrollToTopCallback!(scrollToTop);
      }
    });
  }

  @override
  void didUpdateWidget(AnimePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果回调发生变化，更新它
    if (widget.onScrollToTopCallback != oldWidget.onScrollToTopCallback &&
        widget.onScrollToTopCallback != null) {
      widget.onScrollToTopCallback!(scrollToTop);
    }
  }

  void _scrollListener() {
    // 加载更多数据
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadData();
    }

    // 监听滚动位置，通知父组件返回顶部按钮显示状态
    final shouldShow = _scrollController.position.pixels > 300;
    if (widget.onShowBackToTopChanged != null) {
      widget.onShowBackToTopChanged!(shouldShow);
    }
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // 加载数据
  Future<void> _loadData() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    final hotItem = await BgmRequest.getHotService(_limit, _offset);

    if (mounted) {
      setState(() {
        _dataList.addAll(hotItem.data);
        _offset += hotItem.data.length;
        if (hotItem.data.length < _limit) {
          _hasMore = false;
        }
        _isLoading = false;
      });
    }
  }

  // 获取日历数据
  void _fetchCalendar() async {
    try {
      setState(() {
        _isCalendarLoading = true;
      });
      final response = await BgmRequest.calendarService();
      if (mounted) {
        setState(() {
          _calendar = response;
          _isCalendarLoading = false;
        });
      }
    } catch (e) {
      Logger().e(e);
      if (mounted) {
        setState(() {
          _isCalendarLoading = false;
        });
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_dataList.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints:
                const BoxConstraints(maxWidth: PlayLayoutConstant.maxWidth),
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    CalendarView(
                      calendar: _calendar,
                      isLoading: _isCalendarLoading,
                      onRefresh: _fetchCalendar,
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 20),
                    ),
                    SliverPadding(
                      padding: _contentPadding,
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          const SliverToBoxAdapter(
                            child: Row(
                              children: [
                                Text(
                                  '热门动画',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 5),
                          ),
                          SliverGrid(
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                              LayoutUtil.getCrossAxisCount(context),
                              crossAxisSpacing: 5, // 横向间距
                              mainAxisSpacing: 5, // 纵向间距
                              childAspectRatio: 0.7, // 宽高比
                            ),
                            delegate: SliverChildBuilderDelegate(
                                  (BuildContext context, int index) {
                                if (index == _dataList.length) {
                                  return _hasMore
                                      ? const Center(
                                      child: CircularProgressIndicator())
                                      : const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('没有更多了'),
                                      ));
                                }
                                final subject = _dataList[index].subject;
                                return SubjectCarfView(subject: subject);
                              },
                              childCount: _dataList.length + 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
