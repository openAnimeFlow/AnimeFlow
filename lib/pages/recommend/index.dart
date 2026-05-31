import 'package:anime_flow/pages/recommend/anime/index.dart';
import 'package:anime_flow/pages/recommend/forum/index.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:flutter/material.dart';

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
  final List<Widget> _tabs = [
    const Tab(icon: Icon(Icons.movie_creation_outlined)),
    const Tab(icon: Icon(Icons.forum_outlined)),
  ];

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
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: SearchBar(
                          hintText: 'Search...',
                          elevation: WidgetStateProperty.all(0),
                          backgroundColor: WidgetStateProperty.all(
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          leading: const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.search),
                          ),
                          constraints: const BoxConstraints(minHeight: 44, maxHeight: 44),
                          onTap: () {
                            const SearchRoute().push(context);
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => const PlayRecordRoute().push(context),
                      icon: const Icon(Icons.access_time_outlined),
                    )
                  ],
                )),
          ],
        ),
        bottom: TabBar(
            controller: _tabController,
            tabs: _tabs),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AnimePage(key: _animeKey),
          ForumPage(key: _timelineKey),
        ],
      ),
    );
  }
}
