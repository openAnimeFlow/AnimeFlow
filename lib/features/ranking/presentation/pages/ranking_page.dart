import 'dart:async';
import 'dart:math' as math;

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/core/settings/storage_key.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/ranking/presentation/providers/ranking_provider.dart';
import 'package:anime_flow/features/ranking/presentation/widgets/ranking_grid.dart';
import 'package:anime_flow/features/ranking/presentation/widgets/ranking_list_skeleton.dart';
import 'package:anime_flow/shared/models/enums/sort_type.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:anime_flow/shared/widgets/top_gradient_mask.dart';
import 'package:anime_flow/shared/widgets/bottom_occlusion.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

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
                        MediaQuery.removePadding(
                          context: context,
                          removeLeft: true,
                          child: SliverAppBar(
                            automaticallyImplyLeading: false,
                            titleSpacing: 0,
                            title: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(l10n.rankingTitle),
                            ),
                            toolbarHeight: kToolbarHeight,
                            pinned: true,
                            backgroundColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            forceMaterialTransparency: true,
                            elevation: 0,
                            scrolledUnderElevation: 0,
                            expandedHeight: kToolbarHeight +
                                _filterHeight +
                                _progressHeight,
                            bottom: PreferredSize(
                              preferredSize:
                                  const Size.fromHeight(_progressHeight),
                              child: isReloading
                                  ? const LinearProgressIndicator(
                                      minHeight: _progressHeight)
                                  : const SizedBox.shrink(),
                            ),
                            flexibleSpace: Stack(
                              fit: StackFit.expand,
                              children: [
                                const Positioned.fill(child: TopGradientMask()),
                                _buildFilterSpace(context),
                              ],
                            ),
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
                          loading: () => SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            sliver: _RankingLoadingSkeleton(
                              contentWidth: contentWidth,
                              isDetailsContent: isDetailsContent,
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
                      final currentYear = DateTime.now().year;
                      return Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 5,
                        children: [
                          _buildFilterMenu<SortType>(
                            triggerLabel: _sortLabel(selectedSort, l10n),
                            icon: Icons.sort,
                            selected: selectedSort,
                            options: SortType.values,
                            optionLabel: (sort) => _sortLabel(sort, l10n),
                            onSelected: notifier.setSort,
                          ),
                          _buildFilterMenu<int?>(
                            triggerLabel: selectedYear == null
                                ? l10n.allYears
                                : l10n.yearSuffix(selectedYear),
                            selected: selectedYear,
                            options: [
                              null,
                              for (var index = 0; index < 20; index++)
                                currentYear - index,
                            ],
                            optionLabel: (year) =>
                                year == null ? l10n.all : l10n.yearSuffix(year),
                            onSelected: notifier.setYear,
                          ),
                          _buildFilterMenu<int?>(
                            triggerLabel: selectedMonth == null
                                ? l10n.allMonths
                                : l10n.monthSuffix(selectedMonth),
                            selected: selectedMonth,
                            options: [
                              null,
                              for (var month = 1; month <= 12; month++) month,
                            ],
                            optionLabel: (month) => month == null
                                ? l10n.all
                                : l10n.monthSuffix(month),
                            onSelected: notifier.setMonth,
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

  Widget _buildFilterMenu<T>({
    required String triggerLabel,
    IconData? icon,
    required T selected,
    required List<T> options,
    required String Function(T) optionLabel,
    required ValueChanged<T> onSelected,
  }) {
    final colors = Theme.of(context).colorScheme;
    return JellyMenu<T>(
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      preferredVerticalDirection: VerticalDirection.down,
      widthSpring: const SpringDescription(
        mass: 1,
        stiffness: 220,
        damping: 27,
      ),
      heightSpring: const SpringDescription(
        mass: 1,
        stiffness: 185,
        damping: 25,
      ),
      triggerBuilder: (context, open) => InkWell(
        onTap: open,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                const SizedBox(width: 4),
              ],
              Text(triggerLabel, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
      menuBuilder: (context, select) {
        final style = TextButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          foregroundColor: colors.onSurface,
          padding: JellyMenu.itemPadding(context),
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
        final bottomOcclusion = BottomOcclusionScope.of(context);
        final menu = SingleChildScrollView(
          padding: const EdgeInsets.all(6),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final option in options)
                  Semantics(
                    selected: option == selected,
                    child: TextButton(
                      style: style,
                      onPressed: () => select(option),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: option == selected
                                ? Icon(Icons.check,
                                    size: 18, color: colors.primary)
                                : null,
                          ),
                          Flexible(child: Text(optionLabel(option))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
        return LayoutBuilder(
          builder: (context, constraints) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: math.max(0, constraints.maxHeight - bottomOcclusion),
            ),
            child: menu,
          ),
        );
      },
      onSelected: onSelected,
    );
  }
}

class _RankingLoadingSkeleton extends StatelessWidget {
  const _RankingLoadingSkeleton({
    required this.contentWidth,
    required this.isDetailsContent,
  });

  final double contentWidth;
  final bool isDetailsContent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final base = colors.surfaceContainerHighest;
    final highlight = Color.lerp(base, colors.surface, 0.7)!;
    Widget block({double? width, required double height, double radius = 14}) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
    const itemCount = 10;
    final posterColumns = (contentWidth / 200).floor().clamp(3, 7);
    const spacing = 10.0;
    final posterWidth =
        (contentWidth - spacing * (posterColumns - 1)) / posterColumns;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: contentWidth < 600 ? 220 : 300,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (_, __) => SizedBox(
                      width: contentWidth / 3.2,
                      child: block(height: double.infinity, radius: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    block(width: 24, height: 24),
                    const SizedBox(width: 10),
                    block(width: 90, height: 22),
                  ],
                ),
                const SizedBox(height: 16),
                if (!isDetailsContent)
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: List.generate(
                      itemCount,
                      (_) =>
                          block(width: posterWidth, height: posterWidth * 1.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isDetailsContent)
          SliverGrid.builder(
            gridDelegate: RankingGrid.detailsGridDelegate(contentWidth),
            itemCount: itemCount,
            itemBuilder: (context, index) => const RankingListSkeleton(),
          ),
      ],
    );
  }
}
