class PlaybackSource {
  final Uri uri;
  final Map<String, String> headers;
  final String? referer;
  final String? userAgent;
  final String? subtitle;
  final bool isLocal;

  const PlaybackSource({
    required this.uri,
    this.headers = const {},
    this.referer,
    this.userAgent,
    this.subtitle,
    this.isLocal = false,
  });
}
