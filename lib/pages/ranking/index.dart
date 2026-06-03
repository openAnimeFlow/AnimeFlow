import 'dart:math' as math;

import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/pages/ranking/provider/ranking_provider.dart';
import 'package:anime_flow/pages/ranking/ranking_filter_bar.dart';
import 'package:anime_flow/pages/ranking/ranking_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> {
  final scrollController = ScrollController();
  bool showBackToTop = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(scrollListener);
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
    final rankingAsync = ref.watch(rankingProvider);
    final rankingState = rankingAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('排行榜'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(rankingProvider.notifier).refresh(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
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
              const SliverAppBar(
                pinned: true,
                floating: true,
                title: RankingFilterBar(),
              ),
              if (rankingState?.errorMessage case final errorMessage?)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Material(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  return SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          _horizontalPadding(constraints.crossAxisExtent),
                    ),
                    sliver: rankingAsync.when(
                      loading: () => const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, _) => SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('加载失败: $error'),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => ref
                                    .read(rankingProvider.notifier)
                                    .refresh(),
                                child: const Text('重试'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (_) => const RankingGrid(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
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
