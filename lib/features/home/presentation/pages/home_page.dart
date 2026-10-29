import 'dart:ui';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/shared/widgets/glass_tab_bar.dart';
import 'package:anime_flow/features/home/presentation/widgets/anime/anime_view.dart';
import 'package:anime_flow/features/home/presentation/widgets/community/community_view.dart';
import 'package:anime_flow/features/home/presentation/widgets/wallpapers/wallpaper_view.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/widgets/top_occlusion.dart';
import 'package:material_ui/material_ui.dart';

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
    return StreamBuilder<bool>(
      stream: AppSettings.watchGlassNavigationStyle(),
      initialData: AppSettings.glassNavigationStyle,
      builder: (context, snapshot) =>
          _buildPage(context, snapshot.data ?? false),
    );
  }

  Widget _buildPage(BuildContext context, bool glassStyle) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final glassHeaderHeight =
        MediaQuery.paddingOf(context).top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: glassStyle,
      appBar: AppBar(
        backgroundColor: glassStyle ? Colors.transparent : null,
        forceMaterialTransparency: glassStyle,
        surfaceTintColor: glassStyle ? Colors.transparent : null,
        elevation: glassStyle ? 0 : null,
        scrolledUnderElevation: glassStyle ? 0 : null,
        title: Row(
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
                  appNavigatorOf(context).openSearch<void>(context);
                },
                readOnly: true,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.downloadsTitle,
            onPressed: () =>
                appNavigatorOf(context).openDownload<void>(context),
            icon: const Icon(Icons.cloud_download_outlined),
          ),
          IconButton(
            tooltip: l10n.playbackHistory,
            onPressed: () =>
                appNavigatorOf(context).openPlayRecord<void>(context),
            icon: const Icon(Icons.access_time_outlined),
          ),
        ],
        bottom: glassStyle
            ? null
            : TabBar(controller: _tabController, tabs: [
                Tab(text: l10n.anime),
                Tab(text: l10n.community),
                Tab(text: l10n.wallpapers),
              ]),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: TopOcclusionScope(
              height: glassStyle ? glassHeaderHeight + GlassTabBar.height : 0,
              child: TabBarView(
                controller: _tabController,
                children: const [AnimeView(), CommunityView(), WallpaperView()],
              ),
            ),
          ),
          if (glassStyle)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: glassHeaderHeight,
              child: IgnorePointer(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: ColoredBox(
                      color: colorScheme.surface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          if (glassStyle)
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
