class CrawlConfigItem {
  final String version;
  final String name;
  final String iconUrl;
  final String baseUrl;
  final String searchUrl;
  final String searchList;
  final String searchName;
  final String searchLink;
  final String lineNames;
  final String lineList;
  final String episode;

  CrawlConfigItem({
    required this.version,
    required this.name,
    required this.iconUrl,
    required this.baseUrl,
    required this.searchUrl,
    required this.searchList,
    required this.searchName,
    required this.searchLink,
    required this.lineNames,
    required this.lineList,
    required this.episode,
  });

  factory CrawlConfigItem.fromJson(Map<String, dynamic> json) {
    return CrawlConfigItem(
      version: json['version'] ?? '',
      name: json['name'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      baseUrl: json['baseUrl'] ?? '',
      searchUrl: json['searchUrl'] ?? '',
      searchList: json['searchList'] ?? '',
      searchName: json['searchName'] ?? '',
      searchLink: json['searchLink'] ?? '',
      lineNames: json['lineNames'] ?? '',
      lineList: json['lineList'] ?? '',
      episode: json['episode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'name': name,
      'iconUrl': iconUrl,
      'baseUrl': baseUrl,
      'searchUrl': searchUrl,
      'searchList': searchList,
      'searchName': searchName,
      'searchLink': searchLink,
      'lineNames': lineNames,
      'lineList': lineList,
      'episode': episode,
    };
  }

  @override
  String toString() {
    return 'CrawlConfigItem{version: $version, name: $name, iconUrl: $iconUrl, baseURL: $baseUrl, searchUrl: $searchUrl, searchList: $searchList, searchName: $searchName, searchLink: $searchLink, lineNames: $lineNames, lineList: $lineList, episode: $episode}';
  }
}