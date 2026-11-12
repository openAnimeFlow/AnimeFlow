import 'dart:math' as math;

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:material_ui/material_ui.dart';

class VideoResourceDownloadPage extends StatelessWidget {
  const VideoResourceDownloadPage({
    super.key,
    required this.subjectName,
    required this.episodes,
  });

  final String subjectName;
  final List<EpisodeData> episodes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.downloadResources)),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const maxPageWidth = 1500.0;
            final horizontalPadding =
                16.0 + math.max(0.0, (constraints.maxWidth - maxPageWidth) / 2);
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverMainAxisGroup(slivers: [
                    SliverToBoxAdapter(
                      child: Card(
                        margin: const EdgeInsets.only(top: 16, bottom: 24),
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subjectName,
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.episodeCount(episodes.length),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (episodes.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            l10n.noEpisodeData,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            l10n.episodeList,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 24),
                        sliver: SliverList.separated(
                          itemCount: episodes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) => _EpisodeCard(
                            episode: episodes[index],
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({required this.episode});

  final EpisodeData episode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final localizedName = episode.nameCN.trim();
    final name = localizedName.isEmpty ? episode.name.trim() : localizedName;
    final sort = episode.sort;
    final number = l10n.episodeNumber(sort % 1 == 0 ? sort.toInt() : sort);
    final duration = episode.duration.trim();
    final airdate = episode.airdate.trim();
    final cover = episode.cover?.trim() ?? '';
    final details = [
      if (name.isNotEmpty) number,
      if (duration.isNotEmpty) duration,
      if (airdate.isNotEmpty) airdate,
    ];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (cover.isNotEmpty) ...[
              AnimationNetworkImage(
                url: cover,
                width: 88,
                height: 50,
                placeholderWidth: 88,
                placeholderHeight: 50,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? number : name,
                      style: theme.textTheme.titleSmall),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      details.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
