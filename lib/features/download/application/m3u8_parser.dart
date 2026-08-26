class M3u8Key {
  const M3u8Key({
    required this.method,
    required this.uri,
    this.iv,
  });

  final String method;
  final String uri;
  final String? iv;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is M3u8Key &&
            method == other.method &&
            uri == other.uri &&
            iv == other.iv;
  }

  @override
  int get hashCode => Object.hash(method, uri, iv);
}

class M3u8Segment {
  const M3u8Segment({
    required this.duration,
    required this.uri,
    required this.discontinuityGroup,
    this.key,
    this.byteRangeLength,
    this.byteRangeStart,
    this.initialization,
  });

  final double duration;
  final String uri;
  final int discontinuityGroup;
  final M3u8Key? key;
  final int? byteRangeLength;
  final int? byteRangeStart;
  final M3u8Initialization? initialization;
}

class M3u8Initialization {
  const M3u8Initialization({
    required this.uri,
    this.byteRangeLength,
    this.byteRangeStart,
  });

  final String uri;
  final int? byteRangeLength;
  final int? byteRangeStart;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is M3u8Initialization &&
            uri == other.uri &&
            byteRangeLength == other.byteRangeLength &&
            byteRangeStart == other.byteRangeStart;
  }

  @override
  int get hashCode => Object.hash(uri, byteRangeLength, byteRangeStart);
}

class M3u8Variant {
  const M3u8Variant({
    required this.bandwidth,
    required this.uri,
    this.resolution,
  });

  final int bandwidth;
  final String uri;
  final String? resolution;
}

class M3u8MasterPlaylist {
  const M3u8MasterPlaylist({required this.variants});

  final List<M3u8Variant> variants;

  M3u8Variant get bestVariant {
    if (variants.isEmpty) {
      throw StateError('M3U8 master playlist has no variants');
    }
    return variants.reduce((a, b) => a.bandwidth >= b.bandwidth ? a : b);
  }
}

class M3u8MediaPlaylist {
  const M3u8MediaPlaylist({
    required this.segments,
    required this.targetDuration,
    required this.isVod,
  });

  final List<M3u8Segment> segments;
  final double targetDuration;
  final bool isVod;
}

enum M3u8Type { master, media }

class M3u8Parser {
  const M3u8Parser._();

  static M3u8Type detectType(String content) {
    return content.contains('#EXT-X-STREAM-INF')
        ? M3u8Type.master
        : M3u8Type.media;
  }

  static String resolveUrl(String baseUrl, String relativeUrl) {
    final trimmed = relativeUrl.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      return trimmed;
    }
    return Uri.parse(baseUrl).resolve(trimmed).toString();
  }

  static M3u8MasterPlaylist parseMasterPlaylist(
    String content,
    String baseUrl,
  ) {
    final lines = _normalizedLines(content);
    final variants = <M3u8Variant>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.startsWith('#EXT-X-STREAM-INF:')) {
        continue;
      }

      final attrs =
          _parseAttributes(line.substring('#EXT-X-STREAM-INF:'.length));
      final uriLine = _nextUriLine(lines, i + 1);
      if (uriLine == null) {
        continue;
      }

      variants.add(
        M3u8Variant(
          bandwidth: int.tryParse(attrs['BANDWIDTH'] ?? '') ?? 0,
          resolution: attrs['RESOLUTION'],
          uri: resolveUrl(baseUrl, uriLine),
        ),
      );
    }

    return M3u8MasterPlaylist(variants: variants);
  }

  static M3u8MediaPlaylist parseMediaPlaylist(
    String content,
    String baseUrl,
  ) {
    final lines = _normalizedLines(content);
    final segments = <M3u8Segment>[];

    var targetDuration = 0.0;
    var hasEndList = false;
    var isExplicitVod = false;
    var isLiveEvent = false;
    var discontinuityGroup = 0;
    var currentDuration = 0.0;
    M3u8Key? currentKey;
    M3u8Initialization? currentInitialization;
    final segmentByteRangeEnds = <String, int>{};
    final initializationByteRangeEnds = <String, int>{};
    (int, int?)? pendingByteRange;

    for (final line in lines) {
      if (line.startsWith('#EXT-X-TARGETDURATION:')) {
        targetDuration = double.tryParse(
              line.substring('#EXT-X-TARGETDURATION:'.length),
            ) ??
            0;
        continue;
      }

      if (line == '#EXT-X-ENDLIST') {
        hasEndList = true;
        continue;
      }

      if (line == '#EXT-X-PLAYLIST-TYPE:VOD') {
        isExplicitVod = true;
        continue;
      }

      if (line == '#EXT-X-PLAYLIST-TYPE:EVENT') {
        isLiveEvent = true;
        continue;
      }

      if (line == '#EXT-X-DISCONTINUITY') {
        discontinuityGroup++;
        continue;
      }

      if (line.startsWith('#EXT-X-KEY:')) {
        currentKey = _parseKey(line, baseUrl);
        continue;
      }

      if (line.startsWith('#EXT-X-MAP:')) {
        final attrs = _parseAttributes(line.substring('#EXT-X-MAP:'.length));
        final uri = attrs['URI'];
        if (uri != null && uri.isNotEmpty) {
          final range = _parseByteRange(attrs['BYTERANGE']);
          final resolvedUri = resolveUrl(baseUrl, uri);
          final start = range?.$2 ?? initializationByteRangeEnds[resolvedUri];
          currentInitialization = M3u8Initialization(
            uri: resolvedUri,
            byteRangeLength: range?.$1,
            byteRangeStart: start,
          );
          if (range != null && start != null) {
            initializationByteRangeEnds[resolvedUri] = start + range.$1;
          }
        }
        continue;
      }

      if (line.startsWith('#EXT-X-BYTERANGE:')) {
        final range = _parseByteRange(
          line.substring('#EXT-X-BYTERANGE:'.length),
        );
        if (range != null) {
          pendingByteRange = range;
        }
        continue;
      }

      if (line.startsWith('#EXTINF:')) {
        currentDuration = double.tryParse(
              line.substring('#EXTINF:'.length).split(',').first,
            ) ??
            0;
        continue;
      }

      if (line.isNotEmpty && !line.startsWith('#')) {
        final resolvedUri = resolveUrl(baseUrl, line);
        final segmentRange = pendingByteRange;
        if (segmentRange != null && segmentRange.$2 == null) {
          final previousEnd = segmentByteRangeEnds[resolvedUri];
          pendingByteRange = (segmentRange.$1, previousEnd);
        }
        final resolvedRange = pendingByteRange;
        segments.add(
          M3u8Segment(
            duration: currentDuration,
            uri: resolvedUri,
            discontinuityGroup: discontinuityGroup,
            key: currentKey,
            byteRangeLength: resolvedRange?.$1,
            byteRangeStart: resolvedRange?.$2,
            initialization: currentInitialization,
          ),
        );
        if (resolvedRange != null && resolvedRange.$2 != null) {
          segmentByteRangeEnds[resolvedUri] =
              resolvedRange.$2! + resolvedRange.$1;
        }
        pendingByteRange = null;
        currentDuration = 0;
      }
    }

    final isVod =
        hasEndList || isExplicitVod || (!isLiveEvent && segments.isNotEmpty);

    return M3u8MediaPlaylist(
      segments: segments,
      targetDuration: targetDuration,
      isVod: isVod,
    );
  }

  static List<M3u8Key> extractUniqueKeys(M3u8MediaPlaylist playlist) {
    final seen = <String>{};
    final keys = <M3u8Key>[];

    for (final segment in playlist.segments) {
      final key = segment.key;
      if (key == null || key.uri.isEmpty || !seen.add(key.uri)) {
        continue;
      }
      keys.add(key);
    }

    return keys;
  }

  static Future<List<M3u8Segment>> resolveNestedSegments(
    List<M3u8Segment> segments,
    Future<String> Function(String url) fetcher, {
    int maxDepth = 3,
  }) async {
    if (maxDepth <= 0 || !segments.any((segment) => _isM3u8Url(segment.uri))) {
      return segments;
    }

    final result = <M3u8Segment>[];
    var groupOffset = 0;

    for (final segment in segments) {
      if (!_isM3u8Url(segment.uri)) {
        result.add(_copySegment(segment, groupOffset: groupOffset));
        continue;
      }

      try {
        final content = await fetcher(segment.uri);
        var playlistUrl = segment.uri;
        var mediaContent = content;

        if (detectType(content) == M3u8Type.master) {
          final master = parseMasterPlaylist(content, segment.uri);
          playlistUrl = master.bestVariant.uri;
          mediaContent = await fetcher(playlistUrl);
        }

        final nestedPlaylist = parseMediaPlaylist(mediaContent, playlistUrl);
        final nestedSegments = await resolveNestedSegments(
          nestedPlaylist.segments,
          fetcher,
          maxDepth: maxDepth - 1,
        );

        if (nestedSegments.isEmpty) {
          continue;
        }

        final nestedBase = segment.discontinuityGroup + groupOffset;
        var maxNestedGroup = 0;
        for (final nested in nestedSegments) {
          if (nested.discontinuityGroup > maxNestedGroup) {
            maxNestedGroup = nested.discontinuityGroup;
          }
          result.add(_copySegment(nested, groupOffset: nestedBase));
        }
        groupOffset += maxNestedGroup;
      } catch (_) {
        result.add(_copySegment(segment, groupOffset: groupOffset));
      }
    }

    return result;
  }

  static String buildLocalM3u8(
    List<M3u8Segment> segments, {
    required double targetDuration,
    Map<String, String> keyUriToLocal = const {},
    Map<M3u8Initialization, String> initializationToLocal = const {},
  }) {
    final buffer = StringBuffer()
      ..writeln('#EXTM3U')
      ..writeln('#EXT-X-VERSION:3')
      ..writeln('#EXT-X-TARGETDURATION:${targetDuration.ceil()}')
      ..writeln('#EXT-X-MEDIA-SEQUENCE:0');

    var lastDiscontinuityGroup = 0;
    M3u8Key? lastKey;

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];

      if (i > 0 && segment.discontinuityGroup != lastDiscontinuityGroup) {
        buffer.writeln('#EXT-X-DISCONTINUITY');
        lastDiscontinuityGroup = segment.discontinuityGroup;
      }

      if (segment.key != lastKey) {
        buffer.writeln(_formatKey(segment.key, keyUriToLocal));
        lastKey = segment.key;
      }

      if (segment.initialization != null &&
          (i == 0 ||
              segment.initialization != segments[i - 1].initialization)) {
        final initialization = segment.initialization!;
        final localPath = initializationToLocal[initialization];
        if (localPath != null) {
          buffer.write('#EXT-X-MAP:URI="$localPath"');
          buffer.writeln();
        }
      }

      buffer
        ..writeln('#EXTINF:${segment.duration.toStringAsFixed(6)},')
        ..writeln('seg_${i.toString().padLeft(5, '0')}.ts');
    }

    buffer.writeln('#EXT-X-ENDLIST');
    return buffer.toString();
  }

  static List<String> _normalizedLines(String content) {
    return content
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  static String? _nextUriLine(List<String> lines, int start) {
    for (var i = start; i < lines.length; i++) {
      final line = lines[i];
      if (!line.startsWith('#')) {
        return line;
      }
      if (line.startsWith('#EXT-X-STREAM-INF:')) {
        return null;
      }
    }
    return null;
  }

  static M3u8Key? _parseKey(String line, String baseUrl) {
    final attrs = _parseAttributes(line.substring('#EXT-X-KEY:'.length));
    final method = attrs['METHOD'] ?? 'NONE';
    if (method == 'NONE') {
      return null;
    }

    final uri = attrs['URI'];
    return M3u8Key(
      method: method,
      uri: uri == null ? '' : resolveUrl(baseUrl, uri),
      iv: attrs['IV'],
    );
  }

  static Map<String, String> _parseAttributes(String input) {
    final attrs = <String, String>{};
    final buffer = StringBuffer();
    var inQuotes = false;

    void flush() {
      final part = buffer.toString().trim();
      buffer.clear();
      if (part.isEmpty) {
        return;
      }

      final separator = part.indexOf('=');
      if (separator <= 0) {
        return;
      }

      final key = part.substring(0, separator).trim();
      var value = part.substring(separator + 1).trim();
      if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }
      attrs[key] = value;
    }

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      }
      if (char == ',' && !inQuotes) {
        flush();
      } else {
        buffer.write(char);
      }
    }
    flush();

    return attrs;
  }

  static (int, int?)? _parseByteRange(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.trim().split('@');
    final length = int.tryParse(parts.first);
    if (length == null || length <= 0) return null;
    final start = parts.length > 1 ? int.tryParse(parts[1]) : null;
    return (length, start);
  }

  static bool _isM3u8Url(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url.toLowerCase().contains('.m3u8');
    return uri.path.toLowerCase().endsWith('.m3u8') ||
        uri.query.toLowerCase().contains('m3u8');
  }

  static M3u8Segment _copySegment(
    M3u8Segment segment, {
    required int groupOffset,
  }) {
    return M3u8Segment(
      duration: segment.duration,
      uri: segment.uri,
      discontinuityGroup: segment.discontinuityGroup + groupOffset,
      key: segment.key,
      byteRangeLength: segment.byteRangeLength,
      byteRangeStart: segment.byteRangeStart,
      initialization: segment.initialization,
    );
  }

  static String _formatKey(
    M3u8Key? key,
    Map<String, String> keyUriToLocal,
  ) {
    if (key == null) {
      return '#EXT-X-KEY:METHOD=NONE';
    }

    final buffer = StringBuffer(
      '#EXT-X-KEY:METHOD=${key.method},URI="${keyUriToLocal[key.uri] ?? key.uri}"',
    );
    if (key.iv != null) {
      buffer.write(',IV=${key.iv}');
    }
    return buffer.toString();
  }
}
