import 'package:anime_flow/pages/recommend/anime/index.dart';
import 'package:anime_flow/pages/recommend/timeline/index.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _animeKey = GlobalKey();
  final _timelineKey = GlobalKey();
  final List<String> _tabs = ['动漫', '时间胶囊'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
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
                      context.push(RouteName.search);
                    },
                    readOnly: true,
                  ),
                ),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => context.push(RouteName.playRecord),
                  icon: const Icon(Icons.access_time_outlined),
                )
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
            })),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AnimePage(key: _animeKey),
          TimelinePage(key: _timelineKey),
        ],
      ),
    );
  }
}
