import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/home/presentation/widgets/anime/anime_view.dart';
import 'package:anime_flow/features/home/presentation/widgets/forum/forum_view.dart';
import 'package:anime_flow/app/router/app_router.dart';
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
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
                child: Row(
              children: [
                Text(l10n.recommendTab),
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
                      hintText: l10n.searchAnimeHint,
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
                      const SearchRoute().push(context);
                    },
                    readOnly: true,
                  ),
                ),
              ],
            )),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.downloadsTitle,
            onPressed: () => const DownloadRoute().push(context),
            icon: const Icon(Icons.cloud_download_rounded),
          ),
          IconButton(
            tooltip: l10n.playbackHistory,
            onPressed: () => const PlayRecordRoute().push(context),
            icon: const Icon(Icons.access_time_outlined),
          ),
        ],
        bottom: TabBar(controller: _tabController, tabs: [
          Tab(text: l10n.animeTab),
          Tab(text: l10n.forumTab),
        ]),
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
