import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../download_directory_platform.dart';

class AndroidDownloadDirectoryPlatform extends DownloadDirectoryPlatform {
  const AndroidDownloadDirectoryPlatform();

  static const _channel = MethodChannel('anime_flow/download_storage');

  @override
  bool get supportsSelection => true;

  @override
  Future<bool> requestAccess() async {
    // The dart:io downloader needs filesystem access; a SAF grant alone
    // does not allow it to write to shared storage on Android.
    return await _channel.invokeMethod<bool>('requestAccess') == true;
  }

  @override
  Future<String?> selectDirectory({required String dialogTitle}) {
    return FilePicker.getDirectoryPath(dialogTitle: dialogTitle);
  }

  @override
  Future<String> restoreAccess(String directory) async {
    final accessible = await _channel.invokeMethod<bool>(
      'hasDirectoryAccess',
      {'path': directory},
    );
    if (accessible != true) throw const DownloadDirectoryAccessException();
    return directory;
  }
}
