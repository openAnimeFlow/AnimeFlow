import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/features/home/presentation/providers/community_provider.dart';
import 'package:anime_flow/shared/models/flow/watching_subject.dart';
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final watching = ref.watch(communityWatchingSubjectsProvider);
    return RefreshIndicator(
      onRefresh: () => ref
          .read(communityWatchingSubjectsProvider.notifier)
          .refresh(),
      child: watching.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _MessageView(
          icon: Icons.cloud_off_outlined,
          message: error.toString(),
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(communityWatchingSubjectsProvider),
        ),
        data: (subjects) {
          if (subjects.isEmpty) {
            return _MessageView(
              icon: Icons.ondemand_video_outlined,
              message: l10n.totalWatchers,
              retryLabel: l10n.retry,
              onRetry: () => ref.invalidate(communityWatchingSubjectsProvider),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1100
                  ? 5
                  : constraints.maxWidth >= 760
                      ? 4
                      : constraints.maxWidth >= 500
                          ? 3
                          : 2;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: subjects.length,
                itemBuilder: (context, index) => _WatchingSubjectCard(
                  subject: subjects[index],
                  watcherLabel: l10n.totalWatchers,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WatchingSubjectCard extends StatelessWidget {
  const _WatchingSubjectCard({
    required this.subject,
    required this.watcherLabel,
  });

  final WatchingSubject subject;
  final String watcherLabel;

  @override
  Widget build(BuildContext context) {
    final imageUrl = subject.images?.common ?? subject.images?.medium ?? '';
    return Card(
      clipBehavior: Clip.antiAlias,
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
              child: imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Colors.black12,
                      child: Icon(Icons.image_not_supported_outlined),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Colors.black12,
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 15),
                      const SizedBox(width: 4),
                      Text('${subject.online.onlineUsers} $watcherLabel'),
                    ],
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

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 260,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 42, color: Colors.grey),
                const SizedBox(height: 12),
                Text(message),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onRetry,
                  child: Text(retryLabel),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
