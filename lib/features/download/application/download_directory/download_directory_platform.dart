import 'dart:io';

import 'package:flutter/foundation.dart';

import 'impl/android_download_directory_platform.dart';
import 'impl/desktop_download_directory_platform.dart';
import 'impl/unsupported_download_directory_platform.dart';

/// Platform operations for configuring a writable download directory.
abstract class DownloadDirectoryPlatform {
  const DownloadDirectoryPlatform();

  bool get supportsSelection;

  /// Returns false when the user declines the required storage access.
  Future<bool> requestAccess();

  /// Returns null when the user cancels directory selection.
  Future<String?> selectDirectory({required String dialogTitle});

  /// Shared filesystem check for platforms used by the dart:io downloader.
  Future<void> verifyWritable(String directory) async {
    try {
      // Use a unique child directory without overwriting existing files.
      final probe = await Directory(directory).createTemp('.anime_flow_');
      try {
        await File('${probe.path}/write_test').writeAsBytes([0], flush: true);
      } finally {
        await probe.delete(recursive: true);
      }
    } on FileSystemException {
      throw const DownloadDirectoryNotWritableException();
    }
  }
}

class DownloadDirectoryNotWritableException implements Exception {
  const DownloadDirectoryNotWritableException();
}

class DownloadDirectoryPlatformFactory {
  static DownloadDirectoryPlatform create() {
    if (kIsWeb) return const UnsupportedDownloadDirectoryPlatform();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => const AndroidDownloadDirectoryPlatform(),
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux =>
        const DesktopDownloadDirectoryPlatform(),
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia =>
        const UnsupportedDownloadDirectoryPlatform(),
    };
  }
}
