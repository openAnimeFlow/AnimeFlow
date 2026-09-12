import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'hls_media_cache.dart';

Future<HlsMediaCache>? _cache;

/// Lives outside a playback route so future export leases survive route exit.
Future<HlsMediaCache> sharedMediaCache() => _cache ??= () async {
      final root = await getTemporaryDirectory();
      return HlsMediaCache(
          directory: Directory(p.join(root.path, 'AnimeFlow', 'media-cache')));
    }();
