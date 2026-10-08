import 'package:file_picker/file_picker.dart';

import '../download_directory_platform.dart';

/// Windows, macOS and Linux share the same directory picker behavior.
class DesktopDownloadDirectoryPlatform extends DownloadDirectoryPlatform {
  const DesktopDownloadDirectoryPlatform();

  @override
  bool get supportsSelection => true;

  @override
  Future<bool> requestAccess() async => true;

  @override
  Future<String?> selectDirectory({required String dialogTitle}) {
    return FilePicker.platform.getDirectoryPath(dialogTitle: dialogTitle);
  }
}
