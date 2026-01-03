import 'package:anime_flow/controllers/app/apply_updates_controller.dart';
import 'package:anime_flow/http/dio/dio_request.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart' show getDownloadsDirectory;
import 'package:path/path.dart' as path;

/// Windows 平台更新实现
class ApplyUpdatesWindowsController implements ApplyUpdatesController {
  CancelToken? _cancelToken;

  @override
  Future<void> applyUpdates(
    String downloadUrl, {
    String? fileName,
    void Function(int received, int total)? onProgress,
  }) async {
    _cancelToken = CancelToken();
    try {
      final tempDir = await getDownloadsDirectory();
      final savePath = path.join(tempDir!.path, fileName ?? 'AnimeFlow.zip');
      await dioRequest.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          onProgress?.call(received, total);
        },
        cancelToken: _cancelToken,
      );
    } catch (e) {
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
