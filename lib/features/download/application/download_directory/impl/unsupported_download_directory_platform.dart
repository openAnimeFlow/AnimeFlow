import '../download_directory_platform.dart';

/// Platforms without support for custom dart:io download directories.
class UnsupportedDownloadDirectoryPlatform extends DownloadDirectoryPlatform {
  const UnsupportedDownloadDirectoryPlatform();

  @override
  bool get supportsSelection => false;

  @override
  Future<bool> requestAccess() async => false;

  @override
  Future<String?> selectDirectory({required String dialogTitle}) async => null;
}
