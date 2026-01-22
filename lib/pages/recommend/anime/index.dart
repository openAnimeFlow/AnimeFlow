import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/pages/recommend/anime/calendar.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/utils/layout_util.dart';
import 'package:anime_flow/widget/subject_card.dart';
import 'package:anime_flow/models/item/bangumi/hot_item.dart';
import 'package:anime_flow/models/item/bangumi/calendar_item.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';

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

class _AnimePageState extends State<AnimePage>
    with AutomaticKeepAliveClientMixin {
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
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                                // 显示数据项
                                if (index < _dataList.length) {
                                  final subject = _dataList[index].subject;
                                  final subjectBasicData = SubjectBasicData(
                                      id: subject.id,
                                      name: subject.nameCN ?? subject.name,
                                      image: subject.images.large);
                                  return InkWell(
                                    onTap: () => Get.toNamed(
                                        RouteName.animeInfo,
                                        arguments: subjectBasicData),
                                    child: SubjectCard(
                                      image: subject.images.large,
                                      title: subject.nameCN ?? subject.name,
                                    ),
                                  );
                                }

                                // 加载时显示骨架屏(3个)
                                final skeletonCount =
                                    _hasMore && _isLoading ? 3 : 0;
                                if (index < _dataList.length + skeletonCount) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: _buildSkeleton(context),
                                    ),
                                  );
                                }

                                return const SizedBox.shrink();
                              },
                              childCount: _dataList.length +
                                  (_hasMore && _isLoading ? 3 : 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 没有更多数据提示
                    if (!_hasMore)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildHorizontalRuleIcons(),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(
                                    '没有更多了',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _buildHorizontalRuleIcons(),
                                ),
                              ],
                            ),
                          ),
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

  // 构建横线图标（填充剩余空间）
  Widget _buildHorizontalRuleIcons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const iconSize = 24.0; // 图标大小
        const spacing = 4.0; // 图标间距
        const iconWidth = iconSize + spacing;
        final iconCount = (constraints.maxWidth / iconWidth).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            iconCount > 0 ? iconCount : 1,
            (index) => Padding(
              padding:
                  EdgeInsets.only(right: index < iconCount - 1 ? spacing : 0),
              child: Icon(
                Icons.horizontal_rule_rounded,
                size: iconSize,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }

  //骨架屏
  Widget _buildSkeleton(BuildContext context) {
    final isDark = Utils.isDarkTheme(context);
    final baseColor = isDark ? Colors.grey[400]! : Colors.grey[200]!;
    final highlightColor = isDark ? Colors.grey[300]! : Colors.grey[100]!;
    final containerColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).colorScheme.surface;
    return Stack(children: [
      Positioned.fill(
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: 100,
            height: 20,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      )
    ]);
  }
}
