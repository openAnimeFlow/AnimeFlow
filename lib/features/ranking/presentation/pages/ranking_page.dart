import 'dart:async';
import 'dart:math' as math;

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/ranking/presentation/providers/ranking_provider.dart';
import 'package:anime_flow/features/ranking/presentation/widgets/ranking_filter_bar.dart';
import 'package:anime_flow/features/ranking/presentation/widgets/ranking_grid.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  final scrollController = ScrollController();
  bool showBackToTop = false;
  bool isDetailsContent = true;

  @override
  void initState() {
    super.initState();
    isDetailsContent =
        AppSettings.getSetting<bool>(SettingKey.rankingDetailsLayout) ?? true;
    scrollController.addListener(scrollListener);
  }

  void toggleLayout() {
    setState(() => isDetailsContent = !isDetailsContent);
    unawaited(AppSettings.setSetting(
      SettingKey.rankingDetailsLayout,
      isDetailsContent,
    ));
  }

  void scrollListener() {
    final shouldShow = scrollController.offset >= 300;
    if (shouldShow != showBackToTop) {
      setState(() {
        showBackToTop = shouldShow;
      });
    }
  }

  void scrollToTop() {
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  double _horizontalPadding(double crossAxisExtent) {
    return math.max(
      10.0,
      (crossAxisExtent - LayoutConstant.maxWidth) / 2 + 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rankingTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = _horizontalPadding(constraints.maxWidth);
          final contentWidth = constraints.maxWidth - horizontalPadding * 2;
          return Consumer(
            builder: (context, ref, child) {
              final rankingAsync = ref.watch(rankingProvider);
              final rankingState = rankingAsync.asData?.value;
              final isReloading = rankingState?.isReloading ?? false;
              return RefreshIndicator(
                  onRefresh: () => ref.read(rankingProvider.notifier).refresh(),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      // 内部横向列表（例如前三名卡片）也会冒泡滚动通知，
                      // 只有外层纵向滚动视图才能触发分页加载。
                      if (notification is ScrollUpdateNotification &&
                          notification.depth == 0 &&
                          notification.metrics.axis == Axis.vertical) {
                        final metrics = notification.metrics;
                        final state = rankingAsync.asData?.value;
                        if (metrics.pixels >= metrics.maxScrollExtent - 200 &&
                            state != null &&
                            state.items.isNotEmpty &&
                            !state.isReloading &&
                            !state.isLoadingMore &&
                            state.hasMore) {
                          ref.read(rankingProvider.notifier).loadMore();
                        }
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverAppBar(
                          pinned: true,
                          floating: true,
                          title: const RankingFilterBar(),
                          bottom: PreferredSize(
                            preferredSize: const Size.fromHeight(4),
                            child: isReloading
                                ? const LinearProgressIndicator(minHeight: 4)
                                : const SizedBox.shrink(),
                          ),
                        ),
                        if (rankingState?.errorMessage case final errorMessage?)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Material(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    errorMessage,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        rankingAsync.when(
                          loading: () => const SliverToBoxAdapter(
                            child: SizedBox(
                              height: 320,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                          error: (error, _) => SliverToBoxAdapter(
                            child: SizedBox(
                              height: 320,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(l10n
                                        .rankingLoadFailed(error.toString())),
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      onPressed: () => ref
                                          .read(rankingProvider.notifier)
                                          .refresh(),
                                      child: Text(l10n.retry),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          data: (_) => SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            sliver: RankingGrid(
                              contentWidth: contentWidth,
                              isDetailsContent: isDetailsContent,
                              onToggleLayout: toggleLayout,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ));
            },
          );
        },
      ),
      floatingActionButton: showBackToTop
          ? FloatingActionButton(
              onPressed: scrollToTop,
              child: Icon(
                Icons.arrow_upward,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : null,
    );
  }
}
