import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/features/home/presentation/providers/community_provider.dart';
import 'package:anime_flow/shared/models/flow/online_count.dart';
import 'package:anime_flow/shared/models/flow/watching_subject.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(communityWatchingSubjectsProvider.notifier).refresh(),
      ref.read(communityOnlineCountProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final watching = ref.watch(communityWatchingSubjectsProvider);
    final onlineCount = ref.watch(communityOnlineCountProvider);
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: colorScheme.primary,
      onRefresh: _refresh,
      child: watching.when(
        loading: () => const _CommunityLoading(),
        error: (error, _) => _CommunityMessage(
          icon: Icons.cloud_off_outlined,
          message: error.toString(),
          retryLabel: l10n.retry,
          onRetry: _refresh,
        ),
        data: (subjects) => _CommunityContent(
          subjects: subjects,
          onlineCount: onlineCount,
          retryLabel: l10n.retry,
          watcherLabel: l10n.totalWatchers,
          onRetry: _refresh,
        ),
      ),
    );
  }
}

class _CommunityContent extends StatelessWidget {
  const _CommunityContent({
    required this.subjects,
    required this.onlineCount,
    required this.retryLabel,
    required this.watcherLabel,
    required this.onRetry,
  });

  final List<WatchingSubject> subjects;
  final AsyncValue<OnlineCount> onlineCount;
  final String retryLabel;
  final String watcherLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final totalWatching = subjects.fold<int>(
      0,
      (total, subject) => total + subject.online.onlineUsers,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 900 ? 32.0 : 16.0;
        final gridWidth = constraints.maxWidth - horizontalPadding * 2;
        final estimatedColumns = (gridWidth / 444).ceil();
        var crossAxisCount = estimatedColumns;
        if (crossAxisCount < 2) crossAxisCount = 2;
        if (crossAxisCount > 4) crossAxisCount = 4;
        final compactGrid = constraints.maxWidth < 500;
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _CommunityHero(
                  onlineCount: onlineCount,
                  onRetry: onRetry,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                28,
                horizontalPadding,
                12,
              ),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: '正在观看的番剧',
                  subtitle: subjects.isEmpty
                      ? null
                      : '共 ${subjects.length} 部 · $totalWatching 人正在观看',
                  icon: Icons.ondemand_video_outlined,
                ),
              ),
            ),
            if (subjects.isEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  8,
                  horizontalPadding,
                  32,
                ),
                sliver: SliverToBoxAdapter(
                  child: _EmptyCommunityCard(
                    onlineCount: onlineCount,
                    retryLabel: retryLabel,
                    onRetry: onRetry,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  8,
                  horizontalPadding,
                  32,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _WatchingSubjectCard(
                      subject: subjects[index],
                      watcherLabel: watcherLabel,
                    ),
                    childCount: subjects.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: compactGrid ? 6 : 5,
                    crossAxisSpacing: compactGrid ? 6 : 5,
                    childAspectRatio: compactGrid ? 1.05 : 1.28,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CommunityHero extends StatelessWidget {
  const _CommunityHero({required this.onlineCount, required this.onRetry});

  final AsyncValue<OnlineCount> onlineCount;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '社区在线',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '因为热爱而相聚 · 与更多同好一起看番',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 22),
        onlineCount.when(
          loading: () => const _StatsCard.loading(),
          error: (_, __) => _StatsCard.loading(onRetry: onRetry),
          data: (count) => _StatsCard(count: count),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.count})
      : onRetry = null,
        loading = false;

  const _StatsCard.loading({this.onRetry})
      : count = null,
        loading = true;

  final OnlineCount? count;
  final Future<void> Function()? onRetry;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final values = count == null
        ? const [0, 0, 0]
        : [count!.onlineUsers, count!.anonymousUsers, count!.loggedInUsers];
    final items = [
      (Icons.groups_rounded, '总人数', values[0], colorScheme.primary),
      (Icons.visibility_off_rounded, '匿名用户', values[1], colorScheme.secondary),
      (Icons.person_rounded, '登录用户', values[2], colorScheme.tertiary),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Expanded(child: _StatItem(item: items[index], loading: loading)),
            if (index != items.length - 1)
              Container(
                height: 45,
                width: 1,
                color: colorScheme.outlineVariant,
              ),
          ],
          if (loading && onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.item, required this.loading});

  final (IconData, String, int, Color) item;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: item.$4.withValues(alpha: .20),
            child: Icon(item.$1, color: item.$4, size: 23),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$2,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loading ? '--' : '${item.$3}',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.icon, this.subtitle});

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: colorScheme.onPrimary, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (subtitle != null)
          Flexible(
            child: Text(
              subtitle!,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _WatchingSubjectCard extends StatelessWidget {
  const _WatchingSubjectCard(
      {required this.subject, required this.watcherLabel});

  final WatchingSubject subject;
  final String watcherLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = subject.images?.common ?? subject.images?.medium ?? '';
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => AnimeInfoRoute(
          id: subject.subjectId,
          name: subject.displayName,
          image: imageUrl,
        ).push(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnimationNetworkImage(
                url: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Row(
                    spacing: 5,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      Text(
                        '${subject.online.onlineUsers} 人在看',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCommunityCard extends StatelessWidget {
  const _EmptyCommunityCard({
    required this.onlineCount,
    required this.retryLabel,
    required this.onRetry,
  });

  final AsyncValue<OnlineCount> onlineCount;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: onlineCount.when(
        loading: () => const SizedBox(height: 130, child: _LoadingIndicator()),
        error: (_, __) =>
            _EmptyMessage(retryLabel: retryLabel, onRetry: onRetry),
        data: (count) => Row(
          children: [
            SizedBox(
              width: 130,
              height: 110,
              child: Image.asset(AssetsPathConstants.purpleCatGirlChibi),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前还没有用户在观看番剧',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '总在线 ${count.onlineUsers} 人 · 匿名 ${count.anonymousUsers} · 登录 ${count.loggedInUsers}',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: Text(retryLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.retryLabel, required this.onRetry});

  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(
          Icons.cloud_off_outlined,
          color: colorScheme.outline,
          size: 38,
        ),
        const SizedBox(height: 8),
        Text(
          '在线人数暂时无法获取',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
      ],
    );
  }
}

class _CommunityMessage extends StatelessWidget {
  const _CommunityMessage({
    required this.icon,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 340,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 42, color: colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommunityLoading extends StatelessWidget {
  const _CommunityLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
