import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/network/clients/flow_client.dart';
import 'package:anime_flow/pages/play/providers/bangumi_recommendation_provider.dart';
import 'package:anime_flow/routes/model/info_route_extra.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/widget/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecommendationsView extends ConsumerWidget {
  const RecommendationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(bangumiRecommendationProvider);

    return recommendations.when(
      loading: () => _buildSection(
        context,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
      ),
      error: (error, _) => _buildSection(
        context,
        child: _RecommendationError(
          message: resolveAnimeFlowErrorMessage(
            error,
            fallback: '推荐数据获取失败',
          ),
          onRetry: () => ref.invalidate(bangumiRecommendationProvider),
        ),
      ),
      data: (item) {
        if (item.data.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildSection(
          context,
          child: Column(
            children: [
              for (final subject in item.data) _RecommendationTile(subject),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('相关推荐'),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile(this.subject);

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = subject.nameCN.isEmpty ? subject.name : subject.nameCN;
    final score = subject.rating.score;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => AnimeInfoRoute.fromExtra(
          InfoRouteExtra(
            id: subject.id,
            name: title,
            image: subject.images.large,
          ),
        ).push(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AnimationNetworkImage(
                  width: 72,
                  height: 104,
                  url: subject.images.common.isNotEmpty
                      ? subject.images.common
                      : subject.images.large,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 104,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (subject.info.isNotEmpty)
                        Text(
                          subject.info,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const Spacer(),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (score > 0)
                            _RecommendationMeta(
                              icon: Icons.star_rounded,
                              label: score.toStringAsFixed(1),
                            ),
                          if (subject.rating.rank > 0)
                            _RecommendationMeta(
                              icon: Icons.leaderboard_rounded,
                              label: '#${subject.rating.rank}',
                            ),
                          if (subject.rating.total > 0)
                            _RecommendationMeta(
                              icon: Icons.people_alt_rounded,
                              label: '${subject.rating.total}',
                            ),
                        ],
                      ),
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

class _RecommendationMeta extends StatelessWidget {
  const _RecommendationMeta({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RecommendationError extends StatelessWidget {
  const _RecommendationError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
