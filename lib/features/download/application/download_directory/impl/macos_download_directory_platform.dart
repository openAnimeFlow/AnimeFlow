import 'package:flutter/services.dart';

import '../download_directory_platform.dart';

/// NSOpenPanel supplies sandbox grants; bookmarks keep them across launches.
class MacOSDownloadDirectoryPlatform extends DownloadDirectoryPlatform {
  const MacOSDownloadDirectoryPlatform();

  static const _channel = MethodChannel('anime_flow/download_directory');

  @override
  bool get supportsSelection => true;

  @override
  Future<bool> requestAccess() async => true;

  @override
  Future<String?> selectDirectory({required String dialogTitle}) =>
      _channel.invokeMethod<String>('selectDirectory', {'title': dialogTitle});

  @override
  Future<void> persistAccess(String directory) =>
      _channel.invokeMethod<void>('persistAccess', {'path': directory});

  @override
  Future<String> restoreAccess(String directory) async {
    final restored = await _channel.invokeMethod<String>(
      'restoreAccess',
      {'path': directory},
    );
    if (restored == null || restored.isEmpty) {
      throw PlatformException(
        code: 'download_directory_access_denied',
        message: '下载目录访问权限失效，请在下载设置中重新选择目录',
      );
    }
    return restored;
  }

  /// Restore every saved root, including roots used by older downloads.
  Future<Map<String, String>> restoreBookmarks() async =>
      await _channel.invokeMapMethod<String, String>('restoreBookmarks') ?? {};
}
