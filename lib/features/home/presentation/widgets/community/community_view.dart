import 'dart:math' as math;

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/core/network/sse/sse_connection_status.dart';
import 'package:anime_flow/features/home/presentation/providers/community_provider.dart';
import 'package:anime_flow/shared/models/flow/online_count.dart';
import 'package:anime_flow/shared/models/flow/watching_subject.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  Future<void> _refresh() async {
    await Future.wait([
      ref.read(communityWatchingSubjectsProvider.notifier).refresh(),
      ref.read(communityOnlineCountProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: SizedBox(
              height: 360,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [0, 0.62, 1],
                ).createShader(bounds),
                child: SvgPicture.asset(
                  AssetsPathConstants.ambientWaveBackground,
                  alignment: Alignment.topCenter,
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    colorScheme.primary.withValues(alpha: 0.42),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
        RefreshIndicator(
          color: colorScheme.primary,
          onRefresh: _refresh,
          child: Consumer(
            builder: (context, ref, _) {
              final watching = ref.watch(communityWatchingSubjectsProvider);
              final onlineCount = ref.watch(communityOnlineCountProvider);
              final connection = ref.watch(communityConnectionProvider);

              return _CommunityContent(
                subjects: watching.value ?? const <WatchingSubject>[],
                onlineCount: onlineCount,
                connection: connection,
                connectionError: watching.error ?? onlineCount.error,
                retryLabel: l10n.retry,
                sectionTitle: l10n.watchingAnimeTitle,
                sectionSummary: (count, viewers) =>
                    l10n.watchingAnimeSummary(count, viewers),
                watchingPeopleLabel: l10n.watchingPeople,
                emptyMessage: l10n.noUsersWatchingAnime,
                onlineSummary: (count) => l10n.communityOnlineSummary(
                  count.onlineUsers,
                  count.anonymousUsers,
                  count.loggedInUsers,
                ),
                onRetry: _refresh,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CommunityContent extends StatelessWidget {
  const _CommunityContent({
    required this.subjects,
    required this.onlineCount,
    required this.connection,
    required this.connectionError,
    required this.retryLabel,
    required this.sectionTitle,
    required this.sectionSummary,
    required this.watchingPeopleLabel,
    required this.emptyMessage,
    required this.onlineSummary,
    required this.onRetry,
  });

  final List<WatchingSubject> subjects;
  final AsyncValue<OnlineCount> onlineCount;
  final CommunityConnectionState connection;
  final Object? connectionError;
  final String retryLabel;
  final String sectionTitle;
  final String Function(int count, int viewers) sectionSummary;
  final String Function(int count) watchingPeopleLabel;
  final String emptyMessage;
  final String Function(OnlineCount count) onlineSummary;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final totalWatching = subjects.fold<int>(
      0,
      (total, subject) => total + subject.online.onlineUsers,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = math.max(
          10.0,
          (constraints.maxWidth - LayoutConstant.maxWidth) / 2 + 10,
        );
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
                5,
                horizontalPadding,
                5,
              ),
              sliver: SliverToBoxAdapter(
                child: _CommunityHero(
                  onlineCount: onlineCount,
                  connection: connection,
                  connectionError: connectionError,
                  title: AppLocalizations.of(context).communityOnlineTitle,
                  subtitle:
                      AppLocalizations.of(context).communityOnlineSubtitle,
                  versionNotice:
                      AppLocalizations.of(context).communityOnlineVersionNotice,
                  totalLabel: AppLocalizations.of(context).totalOnlineUsers,
                  anonymousLabel: AppLocalizations.of(context).anonymousUsers,
                  loggedInLabel: AppLocalizations.of(context).loggedInUsers,
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
                  title: sectionTitle,
                  subtitle: subjects.isEmpty
                      ? null
                      : sectionSummary(subjects.length, totalWatching),
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
                    emptyMessage: emptyMessage,
                    onlineSummary: onlineSummary,
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
                      watchingPeopleLabel: watchingPeopleLabel,
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
  const _CommunityHero({
    required this.onlineCount,
    required this.connection,
    required this.connectionError,
    required this.title,
    required this.subtitle,
    required this.versionNotice,
    required this.totalLabel,
    required this.anonymousLabel,
    required this.loggedInLabel,
    required this.onRetry,
  });

  final AsyncValue<OnlineCount> onlineCount;
  final CommunityConnectionState connection;
  final Object? connectionError;
  final String title;
  final String subtitle;
  final String versionNotice;
  final String totalLabel;
  final String anonymousLabel;
  final String loggedInLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ConnectionIndicator(
                  status: connection.overall,
                  l10n: AppLocalizations.of(context),
                  detail: connectionError?.toString(),
                ),
                if (connection.overall == SseConnectionStatus.error)
                  IconButton(
                    tooltip:
                        AppLocalizations.of(context).communityConnectionRetry,
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          versionNotice,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 22),
        onlineCount.when(
          loading: () => _StatsCard.loading(
            totalLabel: totalLabel,
            anonymousLabel: anonymousLabel,
            loggedInLabel: loggedInLabel,
          ),
          error: (error, __) => _StatsCard.error(
            error: error,
            totalLabel: totalLabel,
            anonymousLabel: anonymousLabel,
            loggedInLabel: loggedInLabel,
          ),
          data: (count) => _StatsCard(
            count: count,
            totalLabel: totalLabel,
            anonymousLabel: anonymousLabel,
            loggedInLabel: loggedInLabel,
          ),
        ),
      ],
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({
    required this.status,
    required this.l10n,
    this.detail,
  });

  final SseConnectionStatus status;
  final AppLocalizations l10n;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color, icon) = switch (status) {
      SseConnectionStatus.connected => (
          l10n.communityConnectionConnected,
          Colors.green,
          Icons.wifi_tethering_rounded,
        ),
      SseConnectionStatus.reconnecting => (
          l10n.communityConnectionReconnecting,
          colorScheme.tertiary,
          Icons.sync_rounded,
        ),
      SseConnectionStatus.error => (
          l10n.communityConnectionError,
          colorScheme.error,
          Icons.wifi_off_rounded,
        ),
      SseConnectionStatus.disconnected => (
          l10n.communityConnectionDisconnected,
          colorScheme.outline,
          Icons.cloud_off_rounded,
        ),
      SseConnectionStatus.connecting => (
          l10n.communityConnectionConnecting,
          colorScheme.primary,
          Icons.sync_rounded,
        ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (detail != null && status == SseConnectionStatus.error)
          SizedBox(
            width: 180,
            child: Text(
              detail!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.count,
    required this.totalLabel,
    required this.anonymousLabel,
    required this.loggedInLabel,
  })  : loading = false,
        error = null;

  const _StatsCard.loading({
    required this.totalLabel,
    required this.anonymousLabel,
    required this.loggedInLabel,
  })  : count = null,
        loading = true,
        error = null;

  const _StatsCard.error({
    required this.error,
    required this.totalLabel,
    required this.anonymousLabel,
    required this.loggedInLabel,
  })  : count = null,
        loading = false;

  final OnlineCount? count;
  final String totalLabel;
  final String anonymousLabel;
  final String loggedInLabel;
  final bool loading;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colorScheme.error.withValues(alpha: .45)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    final values = count == null
        ? const [0, 0, 0]
        : [count!.onlineUsers, count!.anonymousUsers, count!.loggedInUsers];
    final items = [
      (Icons.groups_rounded, totalLabel, values[0], colorScheme.primary),
      (
        Icons.visibility_off_rounded,
        anonymousLabel,
        values[1],
        colorScheme.secondary
      ),
      (Icons.person_rounded, loggedInLabel, values[2], colorScheme.tertiary),
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
      {required this.subject, required this.watchingPeopleLabel});

  final WatchingSubject subject;
  final String Function(int count) watchingPeopleLabel;

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
                        watchingPeopleLabel(subject.online.onlineUsers),
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
    required this.emptyMessage,
    required this.onlineSummary,
    required this.onRetry,
  });

  final AsyncValue<OnlineCount> onlineCount;
  final String retryLabel;
  final String emptyMessage;
  final String Function(OnlineCount count) onlineSummary;
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
              child: Image.asset(AssetsPathConstants.logo),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emptyMessage,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    onlineSummary(count),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
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
