import 'dart:math' as math;

import 'package:anime_flow/features/home/presentation/providers/anime_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/features/home/presentation/widgets/anime/calendar.dart';
import 'package:anime_flow/features/home/presentation/widgets/anime/popular_anime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'play_record.dart';

class AnimeView extends ConsumerStatefulWidget {
  const AnimeView({super.key});

  @override
  ConsumerState<AnimeView> createState() => _AnimePageState();
}

class _AnimePageState extends ConsumerState<AnimeView>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final _showBackToTopButton = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final position = _scrollController.position;
    if (position.pixels > 0) {
      ref.read(animeHotProvider.notifier).markScrolled();
    }
    if (position.extentAfter <= 200) {
      final hotState = ref.read(animeHotProvider).asData?.value;
      if (hotState != null &&
          !hotState.isLoading &&
          !hotState.isRefreshing &&
          !hotState.hasUpdate &&
          hotState.errorMessage == null &&
          hotState.hasMore) {
        ref.read(animeHotProvider.notifier).loadMore();
      }
    }

    _showBackToTopButton.value = position.pixels > 300;
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _showBackToTopButton.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ValueListenableBuilder<bool>(
      valueListenable: _showBackToTopButton,
      builder: (context, visible, child) => Scaffold(
        body: child,
        floatingActionButton: visible
            ? FloatingActionButton(
                onPressed: scrollToTop,
                child: const Icon(Icons.arrow_upward_rounded),
              )
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = math.max(
            10.0,
            (constraints.maxWidth - LayoutConstant.maxWidth) / 2 + 10,
          );
          final contentWidth =
              math.max(0.0, constraints.maxWidth - horizontalPadding * 2);
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    const CalendarView(),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 15),
                    ),
                    const PlayRecordView(),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 15),
                    ),
                    PopularAnimeView(contentWidth: contentWidth),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
