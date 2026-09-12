import 'package:anime_flow/features/download/application/m3u8_parser.dart';

enum MediaCacheIssue {
  disabled,
  localFile,
  preparing,
  ready,
  unsupported,
  timelineChanged,
  unavailable,
  capacity,
  sourceChanged
}

class MediaCacheException implements Exception {
  const MediaCacheException(this.issue, this.message);
  final MediaCacheIssue issue;
  final String message;
  @override
  String toString() => message; // Never include URLs or authentication headers.
}

/// Immutable timeline for the supported HLS subset. Unknown playback-altering
/// tags are rejected instead of being silently stripped during rewriting.
class HlsSnapshot {
  HlsSnapshot._(
      this.mediaSequence, this.targetDuration, List<M3u8Segment> segments)
      : segments = List.unmodifiable(segments);
  final int mediaSequence;
  final int targetDuration;
  final List<M3u8Segment> segments;
  Duration get duration => Duration(
      microseconds:
          (segments.fold<double>(0, (sum, s) => sum + s.duration) * 1000000)
              .round());

  static List<String> checkedLines(String content, {required bool master}) {
    final lines = content
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty || lines.first != '#EXTM3U') unsupported();
    const common = {'#EXTM3U', '#EXT-X-VERSION', '#EXT-X-INDEPENDENT-SEGMENTS'};
    const media = {
      '#EXTINF',
      '#EXT-X-TARGETDURATION',
      '#EXT-X-MEDIA-SEQUENCE',
      '#EXT-X-ENDLIST',
      '#EXT-X-PLAYLIST-TYPE',
      '#EXT-X-PROGRAM-DATE-TIME'
    };
    const variants = {'#EXT-X-STREAM-INF'};
    for (final line in lines) {
      if (line.startsWith('#EXT') &&
          !{...common, ...(master ? variants : media)}
              .contains(line.split(':').first)) {
        unsupported();
      }
    }
    return lines;
  }

  factory HlsSnapshot.parse(String content, Uri base) {
    final lines = checkedLines(content, master: false);
    if (!lines.contains('#EXT-X-ENDLIST') ||
        lines
            .where((l) => l.startsWith('#EXT-X-PLAYLIST-TYPE:'))
            .any((l) => l != '#EXT-X-PLAYLIST-TYPE:VOD')) {
      unsupported();
    }
    final targets =
        lines.where((l) => l.startsWith('#EXT-X-TARGETDURATION:')).toList();
    final sequences =
        lines.where((l) => l.startsWith('#EXT-X-MEDIA-SEQUENCE:')).toList();
    final target = targets.length == 1
        ? int.tryParse(targets.single.split(':').last)
        : null;
    final sequence = sequences.isEmpty
        ? 0
        : sequences.length == 1
            ? int.tryParse(sequences.single.split(':').last)
            : null;
    if (target == null || target <= 0 || sequence == null || sequence < 0) {
      unsupported();
    }
    var pending = false;
    for (final line in lines) {
      if (line.startsWith('#EXTINF:')) {
        if (pending) unsupported();
        pending = true;
      } else if (!line.startsWith('#')) {
        if (!pending) unsupported();
        pending = false;
        checkHttpUri(base.resolve(line));
      }
    }
    if (pending) unsupported();
    final parsed = M3u8Parser.parseMediaPlaylist(content, base.toString());
    if (parsed.segments.isEmpty ||
        parsed.segments.length > 20000 ||
        parsed.segments.any((s) =>
            !s.duration.isFinite ||
            s.duration <= 0 ||
            s.duration.round() > target)) {
      unsupported();
    }
    return HlsSnapshot._(sequence, target, parsed.segments);
  }

  String playlist(Uri Function(int) segmentUri, {int first = 0, int? last}) {
    final buffer =
        StringBuffer('#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-PLAYLIST-TYPE:VOD\n')
          ..writeln('#EXT-X-TARGETDURATION:$targetDuration')
          ..writeln('#EXT-X-MEDIA-SEQUENCE:${mediaSequence + first}');
    for (var i = first; i <= (last ?? segments.length - 1); i++) {
      buffer
        ..writeln('#EXTINF:${segments[i].duration.toStringAsFixed(6)},')
        ..writeln(segmentUri(i));
    }
    return '$buffer#EXT-X-ENDLIST\n';
  }

  (int, int, Duration) range(Duration start, Duration end) {
    if (start < Duration.zero || end < start || end > duration) {
      throw ArgumentError('Invalid media interval');
    }
    var cursor = 0.0;
    int? first;
    var last = segments.length - 1;
    for (var i = 0; i < segments.length; i++) {
      final next = cursor + segments[i].duration;
      if (first == null &&
          (next > start.inMicroseconds / 1000000 || i == segments.length - 1)) {
        first = i;
      }
      if (first != null && next >= end.inMicroseconds / 1000000) {
        last = i;
        break;
      }
      cursor = next;
    }
    final retainedFirst = first! > 0 ? first - 1 : 0;
    final offset = segments
        .take(retainedFirst)
        .fold<double>(0, (sum, s) => sum + s.duration);
    return (
      retainedFirst,
      last,
      Duration(microseconds: (offset * 1000000).round())
    );
  }

  static void checkHttpUri(Uri uri) {
    if (!['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      unsupported();
    }
  }

  static Never unsupported() => throw const MediaCacheException(
      MediaCacheIssue.unsupported, '仅支持未加密、音视频复用且时间轴连续的点播 HLS');
}
