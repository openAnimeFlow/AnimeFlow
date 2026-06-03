import 'package:anime_flow/pages/ranking/provider/ranking_provider.dart';
import 'package:anime_flow/routes/model/info_route_extra.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/layout_util.dart';
import 'package:anime_flow/widget/subject_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RankingGrid extends ConsumerWidget {
  const RankingGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingProvider);

    if (rankingAsync.isLoading && !rankingAsync.hasValue) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final rankingState = rankingAsync.requireValue;

    if (rankingState.items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('暂无数据')),
      );
    }

    final isLoadingMore = rankingState.isLoadingMore && rankingState.hasMore;
    final extraItemCount =
        rankingState.hasMore || rankingState.isReloading ? 1 : 0;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      sliver: SliverGrid.builder(
        itemCount: rankingState.items.length + extraItemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: LayoutUtil.getCrossAxisCount(context),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (context, index) {
          if (index == rankingState.items.length) {
            if (rankingState.isReloading) {
              return const Center(child: CircularProgressIndicator());
            }
            return isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('到底了'),
                    ),
                  );
          }

          final data = rankingState.items[index];
          final subjectBasicData = InfoRouteExtra(
            id: data.id,
            name: data.nameCN.isEmpty ? data.name : data.nameCN,
            image: data.images.large,
          );

          return InkWell(
            onTap: () =>
                AnimeInfoRoute.fromExtra(subjectBasicData).push(context),
            child: SubjectCard(
              rating: data.rating.rank,
              image: data.images.large,
              title: data.nameCN.isEmpty ? data.name : data.nameCN,
            ),
          );
        },
      ),
    );
  }
}
