import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/features/download/application/download_manager.dart';
import 'package:anime_flow/shared/models/download/download_record.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;

/// iOS can relocate the data container while retaining its downloaded files.
/// Rebase recorded app-owned paths before playback, resume or deletion.
Future<void> rebaseIosDownloadPaths(
  Box<DownloadRecord> downloads, {
  Future<String> Function()? downloadDirectory,
}) async {
  try {
    if (downloads.isEmpty) return;
    // iOS always uses app-owned storage, regardless of a saved custom setting.
    final resolve =
        downloadDirectory ?? DownloadManager.getDefaultDownloadDirectory;
    final root = p.normalize(await resolve());
    if (!p.isAbsolute(root)) {
      throw ArgumentError.value(root, 'downloadDirectory', 'Must be absolute');
    }

    final changedRecords = <dynamic, DownloadRecord>{};
    for (final key in downloads.keys.toList()) {
      final record = downloads.get(key);
      if (record == null) continue;
      var changed = false;
      for (final episode in record.episodes.values) {
        var directory = _rebasePath(episode.downloadDirectory, root);
        final media = _rebasePath(episode.localMediaPath, root);
        final danmaku = _rebasePath(episode.localDanmakuPath, root);
        // Older records may have a local file without a recorded directory.
        // Recover that directory so resuming uses the existing files as well.
        if (directory.isEmpty) {
          for (final file in [media, danmaku]) {
            if (file.isNotEmpty && p.isWithin(root, p.dirname(file))) {
              directory = p.dirname(file);
              break;
            }
          }
        }
        if (directory == episode.downloadDirectory &&
            media == episode.localMediaPath &&
            danmaku == episode.localDanmakuPath) {
          continue;
        }
        episode
          ..downloadDirectory = directory
          ..localMediaPath = media
          ..localDanmakuPath = danmaku;
        changed = true;
      }
      if (changed) {
        // Use the actual Hive key, including records saved by older versions.
        changedRecords[key] = record;
      }
    }
    // Update all cached records first so offline playback remains available if
    // persistence fails, for example on a full disk. Disk records are retried
    // from their saved paths on the next launch.
    for (final entry in changedRecords.entries) {
      await downloads.put(entry.key, entry.value);
    }
    if (changedRecords.isNotEmpty) await downloads.flush();
  } catch (error, stackTrace) {
    // No migration flag is saved; failed records can be retried next launch.
    LiggLogger().e('迁移 iOS 下载路径失败', error: error, stackTrace: stackTrace);
  }
}

String _rebasePath(String path, String root) {
  if (path.isEmpty || p.equals(root, path) || p.isWithin(root, path)) {
    return path;
  }
  // Stored iOS paths are POSIX even when a backup is inspected on Windows.
  if (!p.posix.isAbsolute(path)) return path;
  final parts = p.posix.split(p.posix.normalize(path));
  for (var i = 0; i + 6 < parts.length; i++) {
    if (parts[i] == 'Containers' &&
        parts[i + 1] == 'Data' &&
        parts[i + 2] == 'Application' &&
        parts[i + 4] == 'Library' &&
        parts[i + 5] == 'Application Support' &&
        parts[i + 6] == 'downloads') {
      // Preserve legacy names and the full relative structure; regenerating
      // directory names from episode metadata could strand existing segments.
      return p.normalize(p.joinAll([root, ...parts.skip(i + 7)]));
    }
  }
  // Foreign custom directories and paths outside downloads are not relocated.
  return path;
}
