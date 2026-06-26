class CrawlerEpisodeResourcesItem {
  final String lineNames;
  final List<Episode> episodes;

  CrawlerEpisodeResourcesItem({
    required this.lineNames,
    required this.episodes,
  });

  factory CrawlerEpisodeResourcesItem.fromJson(Map<String, dynamic> json) {
    return CrawlerEpisodeResourcesItem(
      lineNames: json['lineNames'],
      episodes: json['episodes'],
    );
  }

  @override
  String toString() {
    return 'EpisodeResourcesItem{lineNames: $lineNames, episodes: $episodes}';
  }
}

class EpisodeResourcesItem {
  final String subjectsTitle;
  final String lineNames;
  final List<Episode> episodes;
  final double matchRatio;

  EpisodeResourcesItem({
    required this.lineNames,
    required this.episodes,
    required this.subjectsTitle,
    this.matchRatio = 0.0,
  });

  factory EpisodeResourcesItem.fromJson(Map<String, dynamic> json) {
    return EpisodeResourcesItem(
      lineNames: json['lineNames'],
      episodes: json['episodes'],
      subjectsTitle: json['subjectsTitle'],
      matchRatio: (json['matchRatio'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'EpisodeResourcesItem{subjectsTitle: $subjectsTitle, lineNames: $lineNames, episodes: $episodes, matchRatio: $matchRatio}';
  }
}

class Episode {
  final int episodeSort;
  final String like;

  Episode({required this.episodeSort, required this.like});

  @override
  String toString() {
    return 'Episode{episodeSort: $episodeSort, like: $like}';
  }
}
