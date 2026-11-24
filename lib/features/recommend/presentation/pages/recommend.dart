import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/widgets/glass_capsule.dart';
import 'package:anime_flow/shared/widgets/glass_tab_bar.dart';
import 'package:anime_flow/features/recommend/presentation/widgets/anime/anime_view.dart';
import 'package:anime_flow/features/recommend/presentation/widgets/community/community_view.dart';
import 'package:anime_flow/features/recommend/presentation/widgets/wallpapers/wallpaper_view.dart';
import 'package:anime_flow/features/recommend/presentation/widgets/wallpapers/wallpaper_browser.dart';
import 'package:anime_flow/shared/navigation/args/wallpaper_detail_args.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/widgets/top_occlusion.dart';
import 'package:anime_flow/shared/widgets/top_gradient_mask.dart';
import 'package:material_ui/material_ui.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key, required this.active});

  final bool active;

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
    return AnimatedBuilder(
      animation: Listenable.merge([_tabController, _tabController.animation]),
      builder: (context, _) => WallpaperBrowser(
        // Keep the viewport width stable until the tab transition completes.
        active: _tabController.index == 2 ||
            (_tabController.previousIndex == 2 &&
                (_tabController.indexIsChanging ||
                    _tabController.animation!.value != _tabController.index)),
        listBuilder: _buildPage,
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    ValueChanged<WallpaperDetailArgs> onOpenWallpaper,
  ) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final glassHeaderHeight =
        MediaQuery.paddingOf(context).top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        forceMaterialTransparency: true,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Text(l10n.recommend),
            const SizedBox(width: 10),
            Flexible(
              child: SizedBox(
                width: 200,
                height: 35,
                child: GlassCapsule(
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
                      appNavigatorOf(context).openSearch<void>();
                    },
                    readOnly: true,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.downloadsTitle,
            onPressed: () => appNavigatorOf(context).openDownload<void>(),
            icon: const Icon(Icons.cloud_download_outlined),
          ),
          IconButton(
            tooltip: l10n.playbackHistory,
            onPressed: () => appNavigatorOf(context).openPlayRecord<void>(),
            icon: const Icon(Icons.access_time_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: TopOcclusionScope(
              height: glassHeaderHeight + GlassTabBar.height,
              child: TabBarView(
                controller: _tabController,
                children: [
                  const AnimeView(),
                  CommunityView(
                    active: widget.active && _tabController.index == 1,
                  ),
                  WallpaperView(onOpen: onOpenWallpaper),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: glassHeaderHeight + 48,
            child: const TopGradientMask(),
          ),
          Positioned(
            top: glassHeaderHeight,
            left: 0,
            right: 0,
            height: GlassTabBar.height,
            child: GlassTabBar(
              controller: _tabController,
              labels: [l10n.anime, l10n.community, l10n.wallpapers],
            ),
          ),
        ],
      ),
    );
  }
}
