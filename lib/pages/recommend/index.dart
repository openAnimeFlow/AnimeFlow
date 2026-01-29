import 'package:anime_flow/pages/recommend/anime/index.dart';
import 'package:anime_flow/pages/recommend/timeline/index.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anime_flow/controllers/theme_controller.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage>
    with SingleTickerProviderStateMixin {
  late ThemeController themeController;
  late TabController _tabController;
  final _animeKey = GlobalKey();
  final _timelineKey = GlobalKey();
  bool _showBackToTopButton = false;
  VoidCallback? _scrollToTopCallback;
  final List<String> _tabs = ['动漫', '时间胶囊'];

  @override
  void initState() {
    super.initState();
    themeController = Get.find<ThemeController>();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  //返回顶部
  void _scrollToTop() {
    _scrollToTopCallback?.call();
  }

  void _handleShowBackToTopChanged(bool show) {
    if (mounted && _showBackToTopButton != show) {
      setState(() {
        _showBackToTopButton = show;
      });
    }
  }

  void _handleTabChange() {
    // 切换标签页时，重置返回顶部按钮状态
    if (mounted) {
      setState(() {
        if (_tabController.index != 0) {
          _showBackToTopButton = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
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
                    Container(
                      width: 200,
                      height: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
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
                    ),
                  ],
                )),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: List.generate(_tabs.length, (index) {
            return Tab(
              text: _tabs[index],
            );
          })
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AnimePage(
            key: _animeKey,
            onShowBackToTopChanged: _handleShowBackToTopChanged,
            onScrollToTopCallback: (callback) {
              _scrollToTopCallback = callback;
            },
          ),
          TimelinePage(key: _timelineKey),
        ],
      ),
      // TODO 应该在灭个页面中实现返回顶部按钮,不需要通知父组件返回顶部按钮显示状态
      floatingActionButton: _tabController.index == 0 && _showBackToTopButton
          ? FloatingActionButton(
        onPressed: _scrollToTop,
        child: const Icon(Icons.arrow_upward),
      )
          : null,
    );
  }
}
