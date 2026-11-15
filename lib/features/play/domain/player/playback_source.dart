/// 已解析、可交给播放器内核的媒体源。
sealed class PlaybackSource {
  final Uri uri;
  final Map<String, String> headers;
  final String? referer;
  final String? userAgent;
  final String? subtitle;

  const PlaybackSource._({
    required this.uri,
    this.headers = const {},
    this.referer,
    this.userAgent,
    this.subtitle,
  });

  factory PlaybackSource.network({
    required Uri uri,
    Map<String, String> headers = const {},
    String? referer,
    String? userAgent,
    String? subtitle,
  }) {
    if (!uri.hasScheme || uri.isScheme('file')) {
      throw ArgumentError.value(uri, 'uri', 'Expected an absolute network URI');
    }
    return NetworkPlaybackSource._(
      uri: uri,
      headers: Map.unmodifiable(headers),
      referer: referer,
      userAgent: userAgent,
      subtitle: subtitle,
    );
  }

  factory PlaybackSource.localFile(String path) {
    if (path.trim().isEmpty) {
      throw ArgumentError.value(path, 'path', 'Local media path is empty');
    }
    final uri = path.toLowerCase().startsWith('file:')
        ? Uri.parse(path)
        : Uri.file(path);
    if (!uri.isScheme('file') || !uri.hasAbsolutePath) {
      throw ArgumentError.value(
          path, 'path', 'Expected an absolute local file');
    }
    // 验证传入的 file URI 确实能够还原为文件路径（不接受 query/fragment）。
    uri.toFilePath();
    return LocalFilePlaybackSource._(uri: uri);
  }
}

final class NetworkPlaybackSource extends PlaybackSource {
  const NetworkPlaybackSource._({
    required super.uri,
    super.headers,
    super.referer,
    super.userAgent,
    super.subtitle,
  }) : super._();
}

final class LocalFilePlaybackSource extends PlaybackSource {
  const LocalFilePlaybackSource._({required super.uri}) : super._();

  String get path => uri.toFilePath();
}
