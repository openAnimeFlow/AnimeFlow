class CrawlConfigItem {
  final String version;
  final String name;
  final String iconUrl;
  final String baseURL;
  final String searchURL;
  final String searchList;
  final String searchName;
  final String searchLink;
  final String lineNames;
  final String lineList;
  final String episode;
  final MatchVideoConfig matchVideo;

  CrawlConfigItem({
    required this.version,
    required this.name,
    required this.iconUrl,
    required this.baseURL,
    required this.searchURL,
    required this.searchList,
    required this.searchName,
    required this.searchLink,
    required this.lineNames,
    required this.lineList,
    required this.episode,
    required this.matchVideo,
  });

  factory CrawlConfigItem.fromJson(Map<String, dynamic> json) {
    return CrawlConfigItem(
      version: json['version'] ?? '',
      name: json['name'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      baseURL: json['baseURL'] ?? '',
      searchURL: json['searchURL'] ?? '',
      searchList: json['searchList'] ?? '',
      searchName: json['searchName'] ?? '',
      searchLink: json['searchLink'] ?? '',
      lineNames: json['lineNames'] ?? '',
      lineList: json['lineList'] ?? '',
      episode: json['episode'] ?? '',
      matchVideo: MatchVideoConfig.fromJson(
        json['matchVideo'] != null 
          ? Map<String, dynamic>.from(json['matchVideo']) 
          : {}
      ),
    );
  }

  @override
  String toString() {
    return 'CrawlConfigItem{version: $version, name: $name, iconUrl: $iconUrl, baseURL: $baseURL, searchURL: $searchURL, searchList: $searchList, searchName: $searchName, searchLink: $searchLink, lineNames: $lineNames, lineList: $lineList, episode: $episode, matchVideo: $matchVideo}';
  }
}

class MatchVideoConfig {
  final bool enableNestedUrl;
  final String matchNestedUrl;
  final String matchVideoUrl;

  MatchVideoConfig({
    required this.enableNestedUrl,
    required this.matchNestedUrl,
    required this.matchVideoUrl,
  });

  factory MatchVideoConfig.fromJson(Map<String, dynamic> json) {
    return MatchVideoConfig(
      enableNestedUrl: json['enableNestedUrl'] ?? false,
      matchNestedUrl: json['matchNestedUrl'] ?? '',
      matchVideoUrl: json['matchVideoUrl'] ?? '',
    );
  }

  @override
  String toString() {
    return 'MatchVideoConfig{enableNestedUrl: $enableNestedUrl, matchNestedUrl: $matchNestedUrl, matchVideoUrl: $matchVideoUrl}';
  }
}

class VideoConfig extends MatchVideoConfig {
  final String baseURL;

  VideoConfig(
      {required super.enableNestedUrl,
      required super.matchNestedUrl,
      required super.matchVideoUrl,
      required this.baseURL});
}
