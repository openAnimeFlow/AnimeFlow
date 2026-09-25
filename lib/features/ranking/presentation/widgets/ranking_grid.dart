import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/features/ranking/presentation/providers/ranking_provider.dart';
import 'package:anime_flow/shared/models/bangumi/subject_item.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RankingGrid extends ConsumerWidget {
  const RankingGrid({super.key, required this.contentWidth});

  final double contentWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rankingAsync = ref.watch(rankingProvider);

    if (rankingAsync.isLoading && !rankingAsync.hasValue) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final rankingState = rankingAsync.requireValue;
    if (rankingState.items.isEmpty) {
      return SizedBox(
        height: 320,
        child: Center(child: Text(l10n.noData)),
      );
    }

    final items = rankingState.items;
    final isLoadingMore = rankingState.isLoadingMore && rankingState.hasMore;
    final showProgress = isLoadingMore || rankingState.isReloading;
    final listItemCount = items.length > 3 ? items.length - 3 : 0;
    final columnCount = contentWidth >= 900
        ? 3
        : contentWidth >= 600
            ? 2
            : 1;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _FeaturedRankings(items: items.take(3).toList()),
        ),
        SliverToBoxAdapter(
          child: _RankingSectionHeader(
            title: l10n.sortTrends,
            subtitle: l10n.rankingTitle,
          ),
        ),
        if (listItemCount > 0)
          SliverGrid.builder(
            itemCount: listItemCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 160,
            ),
            itemBuilder: (context, index) => _RankingListTile(
              subject: items[index + 3],
              rank: index + 4,
            ),
          ),
        SliverToBoxAdapter(
          child: showProgress
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                  child: Center(child: Text(l10n.rankingEnd)),
                ),
        ),
      ],
    );
  }
}

class _FeaturedRankings extends StatelessWidget {
  const _FeaturedRankings({required this.items});

  final List<Subject> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isCompact = MediaQuery.sizeOf(context).width < 720;
    final cards = items.asMap().entries.map((entry) {
      final rank = entry.key + 1;
      final card = _FeaturedCard(subject: entry.value, rank: rank);
      return isCompact
          ? SizedBox(width: 260, child: card)
          : Expanded(flex: rank == 1 ? 115 : 100, child: card);
    }).toList();

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 24),
        child: isCompact
            ? SizedBox(
                height: 300,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cards.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 5),
                  itemBuilder: (_, index) => cards[index],
                ),
              )
            : Row(
                // The scroll view leaves height unbounded; let cards size themselves.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cards.length > 1) cards[1],
                  const SizedBox(width: 12),
                  cards[0],
                  if (cards.length > 2) ...[
                    const SizedBox(width: 12),
                    cards[2],
                  ],
                ],
              ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.subject, required this.rank});

  final Subject subject;
  final int rank;

  Color _accent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (rank) {
      1 => const Color(0xffffc857),
      2 => scheme.primary,
      _ => const Color(0xffff8f70),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _accent(context);
    final title = subject.nameCN.isEmpty ? subject.name : subject.nameCN;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: rank == 1 ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        onTap: () => AnimeInfoRoute.fromExtra(
          InfoRouteExtra(
              id: subject.id, name: title, image: subject.images.large),
        ).push(context),
        child: SizedBox(
          height: 300,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimationNetworkImage(
                  url: subject.images.large, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .12),
                      Colors.black.withValues(alpha: .88),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$rank',
                          style: TextStyle(
                            color: color,
                            fontSize: rank == 1 ? 42 : 34,
                            fontWeight: FontWeight.w900,
                            height: .9,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          rank == 1
                              ? Icons.emoji_events_rounded
                              : Icons.military_tech_rounded,
                          color: color,
                          size: 27,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: color, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          subject.rating.score.toStringAsFixed(1),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '${subject.rating.total} ratings',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankingSectionHeader extends StatelessWidget {
  const _RankingSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded, color: scheme.secondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const Spacer(),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _RankingListTile extends StatelessWidget {
  final Subject subject;
  final int rank;

  const _RankingListTile({required this.subject, required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = subject.nameCN.isEmpty ? subject.name : subject.nameCN;
    final tags = subject.metaTags.take(3).toList();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => AnimeInfoRoute.fromExtra(
          InfoRouteExtra(
              id: subject.id, name: title, image: subject.images.large),
        ).push(context),
        child: SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 100,
                child: AnimationNetworkImage(
                  borderRadius: BorderRadius.circular(15),
                  url: subject.images.small,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (tags.isNotEmpty) ...[
                              const SizedBox(height: 7),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          scheme.primary.withValues(alpha: .12),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      tag,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: scheme.primary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 16, color: scheme.secondary),
                                const SizedBox(width: 3),
                                Text(
                                  subject.rating.score.toStringAsFixed(1),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.secondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(Icons.people_alt_rounded,
                                    size: 14, color: scheme.onSurfaceVariant),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    '${subject.rating.total}',
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$rank',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: rank <= 5
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w900,
                            fontSize: 25),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
