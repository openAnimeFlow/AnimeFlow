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

  /// 从当前平台的绝对文件路径或 file URI 创建本地播放源。
  /// URI 编码保留在这里，由各内核适配其需要的文件表示形式。
  factory PlaybackSource.localFile(String path) {
    if (path.trim().isEmpty) {
      throw ArgumentError.value(path, 'path', 'Local media path is empty');
    }
    final uri = path.toLowerCase().startsWith('file:')
        ? Uri.parse(path)
        : Uri.file(path);
    if (!uri.isScheme('file') || !uri.hasAbsolutePath) {
      throw ArgumentError.value(path, 'path', 'Expected an absolute local file');
    }
    // 验证传入的 file URI 确实能够还原为文件路径（不接受 query/fragment）。
    uri.toFilePath();
    return PlaybackSource(uri: uri, isLocal: true);
  }
}
