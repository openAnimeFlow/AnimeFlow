import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:path/path.dart' as p;

import 'download_directory_platform.dart';
import 'impl/macos_download_directory_platform.dart';

/// Run before rendering download lists or handing local paths to the player.
Future<void> restoreDownloadDirectoryAccess() async {
  final platform = DownloadDirectoryPlatformFactory.create();
  if (platform is! MacOSDownloadDirectoryPlatform) return;
  try {
    final roots = await platform.restoreBookmarks();
    for (final record in Storage.downloads.values.toList()) {
      var changed = false;
      for (final episode in record.episodes.values) {
        final directory = remapDownloadPath(episode.downloadDirectory, roots);
        final media = remapDownloadPath(episode.localMediaPath, roots);
        final danmaku = remapDownloadPath(episode.localDanmakuPath, roots);
        if (directory != episode.downloadDirectory ||
            media != episode.localMediaPath ||
            danmaku != episode.localDanmakuPath) {
          episode
            ..downloadDirectory = directory
            ..localMediaPath = media
            ..localDanmakuPath = danmaku;
          changed = true;
        }
      }
      if (changed) {
        await Storage.downloads.put(record.key, record);
      }
    }
    final configured = AppSettings.downloadDirectory;
    final restored = remapDownloadPath(configured, roots);
    if (restored != configured) {
      await AppSettings.setDownloadDirectory(restored);
    }
  } catch (error, stackTrace) {
    // Failed grants must not prevent launching or choosing a new directory.
    LiggLogger().e('恢复 macOS 下载目录权限失败', error: error, stackTrace: stackTrace);
  }
}

/// Bookmarks follow moved folders. Never redirect files under unrelated roots.
String remapDownloadPath(String path, Map<String, String> roots) {
  if (path.isEmpty) return path;
  final sortedRoots = roots.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final root in sortedRoots) {
    if (p.equals(root, path)) return roots[root]!;
    if (p.isWithin(root, path)) {
      return p.normalize(p.join(roots[root]!, p.relative(path, from: root)));
    }
  }
  return path;
}
