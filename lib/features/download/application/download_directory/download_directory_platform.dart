import 'dart:io';

import 'package:flutter/foundation.dart';

import 'impl/android_download_directory_platform.dart';
import 'impl/desktop_download_directory_platform.dart';
import 'impl/ios_download_directory_platform.dart';
import 'impl/unsupported_download_directory_platform.dart';

/// Platform operations for configuring a writable download directory.
abstract class DownloadDirectoryPlatform {
  const DownloadDirectoryPlatform();

  bool get supportsSelection;

  /// Returns false when the user declines the required storage access.
  Future<bool> requestAccess();

  /// Returns null when the user cancels directory selection.
  Future<String?> selectDirectory({required String dialogTitle});

  /// Restore persisted access before using saved paths.
  Future<void> initialize() async {}

  String resolvePath(String path) => path;

  bool fileExists(String path) => File(resolvePath(path)).existsSync();

  Future<String> prepareDownloadDirectory(String directory) async =>
      resolvePath(directory);

  Future<String> publishDownloadDirectory(String directory) async => directory;

  Future<void> discardDownloadStaging(String directory) async {}

  Future<String> prepareForReading(String path) async => resolvePath(path);

  Future<void> writeTextFile(String path, String contents) async {
    final file = File(resolvePath(path));
    await file.parent.create(recursive: true);
    await file.writeAsString(contents);
  }

  Future<void> deleteDirectory(String path) async {
    final directory = Directory(resolvePath(path));
    if (await directory.exists()) await directory.delete(recursive: true);
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

class DownloadDirectoryNotWritableException implements Exception {
  const DownloadDirectoryNotWritableException();
}

class DownloadDirectoryPlatformFactory {
  static final _ios = IosDownloadDirectoryPlatform();

  static DownloadDirectoryPlatform create() {
    if (kIsWeb) return const UnsupportedDownloadDirectoryPlatform();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => const AndroidDownloadDirectoryPlatform(),
      TargetPlatform.iOS => _ios,
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux =>
        const DesktopDownloadDirectoryPlatform(),
      TargetPlatform.fuchsia => const UnsupportedDownloadDirectoryPlatform(),
    };
  }
}
