import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/pages/recommend/calendar.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/controllers/main_page/main_page_state.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/utils/layout_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' show SizeExtension;
import 'package:get/get.dart';
import 'package:anime_flow/controllers/theme_controller.dart';
import 'package:anime_flow/models/item/bangumi/hot_item.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  late MainPageState mainPageState;
  final List<Data> _dataList = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _showBackToTopButton = false;
  int _offset = 0;
  final int _limit = 20;
  final _scrollController = ScrollController();

  static const _contentPadding = EdgeInsets.all(10);

  @override
  void initState() {
    super.initState();
    mainPageState = Get.find<MainPageState>();
    _loadData();

    _scrollController.addListener(() {
      // 加载更多数据
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadData();
      }

      // 监听滚动位置，控制返回顶部按钮显示
      if (_scrollController.position.pixels > 300) {
        if (!_showBackToTopButton) {
          setState(() {
            _showBackToTopButton = true;
          });
        }
      } else {
        if (_showBackToTopButton) {
          setState(() {
            _showBackToTopButton = false;
          });
        }
      }
    });
  }

  //返回顶部
  void _scrollToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
                child: Row(
              children: [
                const Text("推荐"),
                const SizedBox(width: 10),
                GetBuilder<ThemeController>(
                  builder: (controller) {
                    final borderColor = controller.isDarkMode
                        ? ThemeController.darkTheme.colorScheme.primary
                        : ThemeController.lightTheme.colorScheme.primary;
                    return Container(
                      width: 200,
                      height: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: borderColor,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "搜索动漫番剧...",
                          hintStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 25,
                          ),
                          filled: false,
                          border: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                        onTap: () {
                          Get.toNamed(RouteName.search);
                        },
                        readOnly: true,
                      ),
                    );
                  },
                ),
              ],
            )),
            GetBuilder<ThemeController>(
              builder: (controller) {
                return IconButton(
                  icon: Icon(
                    controller.isDarkMode
                        ? Icons.brightness_7
                        : Icons.brightness_4,
                    color: controller.isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    controller.toggleTheme();
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: _buildPage(),
    );
  }

  Widget _buildPage() {
    if (_dataList.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: PlayLayoutConstant.maxWidth),
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    const CalendarView(),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 20),
                    ),
                    SliverPadding(
                      padding: _contentPadding,
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Row(
                              children: [
                                Text(
                                  "热门动画",
                                  style: TextStyle(
                                      fontSize: 25.sp,
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
                                return _buildCard(subject);
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
            if (_showBackToTopButton)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'recommend_back_to_top',
                  onPressed: _scrollToTop,
                  child: const Icon(Icons.arrow_upward_rounded),
                ),
              )
          ],
        );
      },
    );
  }

  Widget _buildCard(Subject subject) {
    final subjectBasicData = SubjectBasicData(
      id: subject.id,
      name: subject.nameCN ?? subject.name,
      image: subject.images.large,
    );
    return Card(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed(RouteName.animeInfo, arguments: subjectBasicData);
        },
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Stack(
          children: [
            Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                right: 0,
                child: AnimationNetworkImage(
                  url: subject.images.large,
                  fit: BoxFit.cover,
                )),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black38,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  subject.nameCN ?? subject.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
