import 'dart:async';
import 'dart:math' as math;

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/core/settings/storage_key.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/ranking/presentation/providers/ranking_provider.dart';
import 'package:anime_flow/features/ranking/presentation/widgets/ranking_grid.dart';
import 'package:anime_flow/shared/models/enums/sort_type.dart';
import 'package:anime_flow/shared/widgets/top_gradient_mask.dart';
import 'package:anime_flow/shared/widgets/bottom_occlusion.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  static const _filterHeight = 56.0;
  static const _progressHeight = 4.0;
  final scrollController = ScrollController();
  final _showBackToTop = ValueNotifier(false);
  final _isPinned = ValueNotifier(false);
  late final _glassNavigationStyle = AppSettings.watchGlassNavigationStyle();
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
    _showBackToTop.value = scrollController.offset >= 300;
    _isPinned.value = scrollController.offset >= _filterHeight;
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
    _showBackToTop.dispose();
    _isPinned.dispose();
    super.dispose();
  }

  double _horizontalPadding(double crossAxisExtent) {
    return math.max(
      10.0,
      (crossAxisExtent - LayoutConstant.maxWidth) / 2 + 10,
    );
  }

  String _sortLabel(SortType type, AppLocalizations l10n) {
    return switch (type) {
      SortType.rank => l10n.sortRank,
      SortType.trends => l10n.sortTrends,
      SortType.collects => l10n.collection,
      SortType.date => l10n.sortDate,
      SortType.title => l10n.sourceName,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: _showBackToTop,
      builder: (context, visible, child) => Scaffold(
        body: child,
        floatingActionButtonLocation:
            OcclusionAwareFabLocation(BottomOcclusionScope.of(context)),
        floatingActionButton: visible
            ? FloatingActionButton(
                heroTag: null,
                onPressed: scrollToTop,
                child: Icon(
                  Icons.arrow_upward,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : null,
      ),
      child: LayoutBuilder(
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
                            state.errorMessage == null &&
                            state.hasMore) {
                          ref.read(rankingProvider.notifier).loadMore();
                        }
                      }
                      return false;
                    },
                    child: OcclusionAwareCustomScrollView(
                      controller: scrollController,
                      slivers: [
                        StreamBuilder<bool>(
                          stream: _glassNavigationStyle,
                          initialData: AppSettings.glassNavigationStyle,
                          builder: (context, snapshot) =>
                              ValueListenableBuilder<bool>(
                            valueListenable: _isPinned,
                            builder: (context, isPinned, child) =>
                                _GradientSliverAppBar(
                              title: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(l10n.rankingTitle),
                              ),
                              isPinned: isPinned,
                              glassStyle: snapshot.data ?? false,
                              expandedHeight: kToolbarHeight +
                                  _filterHeight +
                                  _progressHeight,
                              flexibleSpace: child!,
                              bottom: PreferredSize(
                                preferredSize:
                                    const Size.fromHeight(_progressHeight),
                                child: isReloading
                                    ? const LinearProgressIndicator(
                                        minHeight: _progressHeight)
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            child: _buildFilterSpace(context),
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
    );
  }

  Widget _buildFilterSpace(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Stack(
      children: [
        Positioned(
          top: MediaQuery.paddingOf(context).top + kToolbarHeight,
          bottom: _progressHeight,
          left: 16,
          right: 16,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minHeight: _filterHeight,
              maxHeight: _filterHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final (selectedSort, selectedYear, selectedMonth) =
                          ref.watch(rankingProvider.select((value) {
                        final state = value.asData?.value;
                        return (
                          state?.selectedSort ?? SortType.rank,
                          state?.selectedYear,
                          state?.selectedMonth,
                        );
                      }));
                      final notifier = ref.read(rankingProvider.notifier);
                      return Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 5,
                        children: [
                          PopupMenuButton<SortType>(
                            offset: const Offset(0, 40),
                            initialValue: selectedSort,
                            itemBuilder: (context) {
                              return SortType.values.map((type) {
                                return PopupMenuItem<SortType>(
                                  value: type,
                                  child: Text(_sortLabel(type, l10n)),
                                );
                              }).toList();
                            },
                            onSelected: notifier.setSort,
                            child: _filterChip(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sort, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    _sortLabel(selectedSort, l10n),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          PopupMenuButton<int>(
                            offset: const Offset(0, 40),
                            initialValue: selectedYear ?? -1,
                            child: _filterChip(
                              child: Text(
                                selectedYear == null
                                    ? l10n.allYears
                                    : l10n.yearSuffix(selectedYear),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            itemBuilder: (context) {
                              final currentYear = DateTime.now().year;
                              return [
                                PopupMenuItem<int>(
                                  value: -1,
                                  child: Text(l10n.all),
                                ),
                                ...List.generate(20, (index) {
                                  final year = currentYear - index;
                                  return PopupMenuItem<int>(
                                    value: year,
                                    child: Text(l10n.yearSuffix(year)),
                                  );
                                }),
                              ];
                            },
                            onSelected: (value) {
                              notifier.setYear(value == -1 ? null : value);
                            },
                          ),
                          PopupMenuButton<int>(
                            offset: const Offset(0, 40),
                            initialValue: selectedMonth ?? -1,
                            child: _filterChip(
                              child: Text(
                                selectedMonth == null
                                    ? l10n.allMonths
                                    : l10n.monthSuffix(selectedMonth),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            itemBuilder: (context) {
                              return [
                                PopupMenuItem<int>(
                                  value: -1,
                                  child: Text(l10n.all),
                                ),
                                ...List.generate(12, (index) {
                                  final month = index + 1;
                                  return PopupMenuItem<int>(
                                    value: month,
                                    child: Text(l10n.monthSuffix(month)),
                                  );
                                }),
                              ];
                            },
                            onSelected: (value) {
                              notifier.setMonth(value == -1 ? null : value);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: child,
    );
  }
}

class _GradientSliverAppBar extends StatelessWidget {
  const _GradientSliverAppBar({
    required this.title,
    required this.flexibleSpace,
    required this.expandedHeight,
    required this.isPinned,
    required this.glassStyle,
    this.bottom,
  });

  final Widget title;
  final Widget flexibleSpace;
  final double expandedHeight;
  final bool isPinned;
  final bool glassStyle;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: title,
      toolbarHeight: kToolbarHeight,
      pinned: true,
      backgroundColor: glassStyle ? Colors.transparent : null,
      surfaceTintColor: glassStyle ? Colors.transparent : null,
      forceMaterialTransparency: glassStyle,
      elevation: glassStyle ? 0 : (isPinned ? 4.0 : 0.0),
      scrolledUnderElevation: glassStyle ? 0 : null,
      forceElevated: !glassStyle && isPinned,
      expandedHeight: expandedHeight,
      bottom: bottom,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          if (glassStyle) const Positioned.fill(child: TopGradientMask()),
          flexibleSpace,
        ],
      ),
    );
  }
}
