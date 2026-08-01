import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/bangumi/subject_item.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/features/player/presentation/providers/recommendation_provider.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecommendationsView extends ConsumerWidget {
  const RecommendationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recommendations = ref.watch(recommendationProvider);

    return recommendations.when(
      loading: () => _buildSection(
        context,
        l10n: l10n,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
      ),
      error: (error, _) => _buildSection(
        context,
        l10n: l10n,
        child: _RecommendationError(
          message: resolveAnimeFlowErrorMessage(
            error,
            fallback: l10n.recommendationLoadFailed,
          ),
          onRetry: () => ref.invalidate(recommendationProvider),
          retryLabel: l10n.retry,
        ),
      ),
      data: (item) {
        if (item.data.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildSection(
          context,
          l10n: l10n,
          child: Column(
            children: [
              for (final subject in item.data) _RecommendationTile(subject),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context,
      {required Widget child, required AppLocalizations l10n}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.recommendationsTitle),
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
    required this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

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
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}
