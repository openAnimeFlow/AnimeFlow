import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/home/presentation/widgets/anime/anime_view.dart';
import 'package:anime_flow/features/home/presentation/widgets/community/community_view.dart';
import 'package:anime_flow/features/home/presentation/widgets/github_issue/github_issue_view.dart';
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
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
                child: Row(
              children: [
                Text(l10n.recommend),
                const SizedBox(width: 10),
                Container(
                  width: 200,
                  height: 35,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l10n.searchAnimeHint,
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 22,
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
            icon: const Icon(Icons.cloud_download_outlined),
          ),
          IconButton(
            tooltip: l10n.playbackHistory,
            onPressed: () => const PlayRecordRoute().push(context),
            icon: const Icon(Icons.access_time_outlined),
          ),
        ],
        bottom: TabBar(controller: _tabController, tabs: [
          Tab(text: l10n.anime),
          Tab(text: l10n.community),
          Tab(text: l10n.githubFeedbackTab),
        ]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AnimeView(),
          CommunityView(),
          GitHubIssueView(),
        ],
      ),
    );
  }
}
