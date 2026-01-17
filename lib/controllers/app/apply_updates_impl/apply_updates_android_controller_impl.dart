import 'dart:io';

import 'package:anime_flow/controllers/app/app_info_controller.dart';
import 'package:anime_flow/controllers/app/apply_updates_controller.dart';
import 'package:anime_flow/http/dio/dio_request.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart'
    show getExternalStorageDirectory;

/// Android 平台更新实现
class ApplyUpdatesAndroidController implements ApplyUpdatesController {
  CancelToken? _cancelToken;

  @override
  Future<void> applyUpdates({
    required DownloadInfo downloadInfo,
    void Function(int received, int total)? onProgress,
  }) async {
    _cancelToken = CancelToken();

    try {
      final dir = await getExternalStorageDirectory();
      final savePath = '${dir!.path}/${downloadInfo.fileName}';
      Get.log(savePath);
      await dioRequest.download(downloadInfo.url, savePath,
          onReceiveProgress: (received, total) {
        // 调用进度回调
        onProgress?.call(received, total);
      }, cancelToken: _cancelToken);

      final result = await OpenFilex.open(File(savePath).path);
      if (result.type != ResultType.done) {
        Logger().e('无法打开安装程序，请检查是否授予了安装权限');
        return;
      }
    } catch (e) {
      // 如果是取消操作，不抛出异常
      if (e.toString().contains('下载已取消')) {
        return;
      }
      rethrow;
    } finally {
      _cancelToken = null;
    }
  }

  @override
  void cancelDownload() {
    _cancelToken?.cancel('用户取消下载');
    _cancelToken = null;
  }
}
