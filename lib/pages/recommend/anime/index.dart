import 'dart:math' as math;

import 'package:anime_flow/pages/recommend/anime/provider/anime_provider.dart';
import 'package:flutter/material.dart';
import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/pages/recommend/anime/calendar.dart';
import 'package:anime_flow/pages/recommend/anime/popular_anime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'play_record.dart';

class AnimePage extends ConsumerStatefulWidget {
  const AnimePage({super.key});

  @override
  ConsumerState<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends ConsumerState<AnimePage>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final hotState = ref.read(animeHotProvider).asData?.value;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        hotState != null &&
        !hotState.isLoading &&
        hotState.hasMore) {
      ref.read(animeHotProvider.notifier).loadMore();
    }

    final shouldShow = _scrollController.position.pixels > 300;
    if (shouldShow != _showBackToTopButton && mounted) {
      setState(() {
        _showBackToTopButton = shouldShow;
      });
    }
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
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = math.max(
                10.0,
                (constraints.crossAxisExtent - LayoutConstant.maxWidth) / 2 + 10,
              );
              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: const SliverMainAxisGroup(
                  slivers: [
                    CalendarView(),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 15),
                    ),
                    PlayRecordView(),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 15),
                    ),
                    PopularAnimeView(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
              onPressed: scrollToTop,
              child: const Icon(Icons.arrow_upward_rounded),
            )
          : null,
    );
  }
}
