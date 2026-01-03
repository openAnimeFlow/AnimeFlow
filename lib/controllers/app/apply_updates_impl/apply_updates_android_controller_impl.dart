import 'dart:io';

import 'package:anime_flow/controllers/app/apply_updates_controller.dart';
import 'package:anime_flow/http/dio/dio_request.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart'
    show getExternalStorageDirectory;

/// Android 平台更新实现
class ApplyUpdatesAndroidController implements ApplyUpdatesController {
  @override
  Future<void> applyUpdates(
    String downloadUrl, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await getExternalStorageDirectory();
    final savePath = '${dir!.path}/AnimeFlow.apk';
    await dioRequest.download(
      downloadUrl,
      savePath,
      onReceiveProgress: (received, total) {
        // 调用进度回调
        onProgress?.call(received, total);
      },
    );
    await OpenFilex.open(File(savePath).path);
  }
}
