class GithubRelease {
  const GithubRelease({
    required this.name,
    required this.tagName,
    required this.createdAt,
    required this.body,
    required this.htmlUrl,
  });

  factory GithubRelease.fromJson(Map<String, dynamic> json) {
    return GithubRelease(
      name: json['name']?.toString() ?? '',
      tagName: json['tag_name']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      htmlUrl: json['html_url']?.toString() ?? '',
    );
  }

  final String name;
  final String tagName;
  final String createdAt;
  final String body;
  final String htmlUrl;
}