import 'dart:io';

import 'package:flutter/foundation.dart';

import 'impl/android_download_directory_platform.dart';
import 'impl/desktop_download_directory_platform.dart';
import 'impl/macos_download_directory_platform.dart';
import 'impl/unsupported_download_directory_platform.dart';

/// Platform operations for configuring a writable download directory.
abstract class DownloadDirectoryPlatform {
  const DownloadDirectoryPlatform();

  bool get supportsSelection;

  /// Returns false when the user declines the required storage access.
  Future<bool> requestAccess();

  /// Returns null when the user cancels directory selection.
  Future<String?> selectDirectory({required String dialogTitle});

  /// Persist only after the selected directory passes write verification.
  Future<void> persistAccess(String directory) async {}

  /// Restore access without presenting a permission dialog.
  Future<String> restoreAccess(String directory) async => directory;

  /// Preflight every download/resume, including directories that already exist.
  /// Permission restoration must stay noninteractive in background tasks.
  Future<String> requireWritableDirectory(String directory) async {
    final restored = await restoreAccess(directory);
    try {
      await Directory(restored).create(recursive: true);
      await verifyWritable(restored);
    } on FileSystemException {
      throw const DownloadDirectoryNotWritableException();
    }
    return restored;
  }

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

abstract class DownloadDirectoryException implements Exception {
  const DownloadDirectoryException();

  String get code;

  @override
  String toString() => code;
}

class DownloadDirectoryNotWritableException extends DownloadDirectoryException {
  const DownloadDirectoryNotWritableException();

  static const errorCode = 'download_directory_not_writable';

  @override
  String get code => errorCode;
}

class DownloadDirectoryAccessException extends DownloadDirectoryException {
  const DownloadDirectoryAccessException();

  static const errorCode = 'download_directory_access_denied';

  @override
  String get code => errorCode;
}

class DownloadDirectoryPlatformFactory {
  static DownloadDirectoryPlatform create() {
    if (kIsWeb) return const UnsupportedDownloadDirectoryPlatform();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => const AndroidDownloadDirectoryPlatform(),
      TargetPlatform.macOS => const MacOSDownloadDirectoryPlatform(),
      TargetPlatform.windows ||
      TargetPlatform.linux =>
        const DesktopDownloadDirectoryPlatform(),
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia =>
        const UnsupportedDownloadDirectoryPlatform(),
    };
  }
}
