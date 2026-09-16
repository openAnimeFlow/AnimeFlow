class GithubRelease {
  const GithubRelease({
    required this.name,
    required this.tagName,
    required this.createdAt,
    required this.body,
    required this.htmlUrl,
    this.assets = const [],
  });

  factory GithubRelease.fromJson(Map<String, dynamic> json) {
    return GithubRelease(
      name: json['name']?.toString() ?? '',
      tagName: json['tag_name']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      htmlUrl: json['html_url']?.toString() ?? '',
      assets: (json['assets'] is List)
          ? (json['assets'] as List)
              .whereType<Map>()
              .map((item) => GithubReleaseAsset.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [],
    );
  }

  final String name;
  final String tagName;
  final String createdAt;
  final String body;
  final String htmlUrl;
  final List<GithubReleaseAsset> assets;
}

class GithubReleaseAsset {
  const GithubReleaseAsset({
    required this.name,
    required this.size,
    required this.browserDownloadUrl,
  });

  factory GithubReleaseAsset.fromJson(Map<String, dynamic> json) {
    return GithubReleaseAsset(
      name: json['name']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      browserDownloadUrl: json['browser_download_url']?.toString() ?? '',
    );
  }

  final String name;
  final int size;
  final String browserDownloadUrl;
}
