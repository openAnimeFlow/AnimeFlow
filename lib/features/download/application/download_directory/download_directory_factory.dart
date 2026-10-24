import 'package:flutter/foundation.dart';
import 'download_directory_platform.dart';
import 'impl/android_download_directory_platform.dart';
import 'impl/desktop_download_directory_platform.dart';
import 'impl/macos_download_directory_platform.dart';
import 'impl/unsupported_download_directory_platform.dart';

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
