import 'package:anime_flow/features/app_update/application/apply_updates_controller.dart';
import 'package:anime_flow/shared/models/download_info.dart';
import 'package:anime_flow/core/network/api/api.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart' show getDownloadsDirectory;
import 'package:path/path.dart' as path;
import 'dart:io';

/// Windows 平台更新实现
class ApplyUpdatesWindowsController implements ApplyUpdatesController {
  CancelToken? _cancelToken;

  @override
  bool get supportsInAppDownload => true;

  @override
  List<DownloadInfo> prioritizeDownloads(List<DownloadInfo> downloads) {
    final installers = downloads
        .where((download) =>
            path.extension(download.fileName).toLowerCase() == '.exe')
        .toList();
    final otherDownloads = downloads
        .where((download) =>
            path.extension(download.fileName).toLowerCase() != '.exe')
        .toList();
    return [...installers, ...otherDownloads];
  }

  @override
  Future<void> openDownloadedPackage(String filePath) async {
    if (path.extension(filePath).toLowerCase() == '.exe') {
      await Process.start(filePath, const [], runInShell: true);
      return;
    }

    await Process.start(
      'explorer.exe',
      ['/select,', filePath],
      runInShell: true,
    );
  }

  @override
  Future<UpdateDownloadResult?> applyUpdates({
    required DownloadInfo downloadInfo,
    void Function(int received, int total)? onProgress,
  }) async {
    _cancelToken = CancelToken();
    try {
      final tempDir = await getDownloadsDirectory();
      final savePath = path.join(tempDir!.path, downloadInfo.fileName);
      await Api.downloadFile(
        downloadInfo.url,
        savePath,
        onReceiveProgress: (received, total) {
          onProgress?.call(received, total);
        },
        cancelToken: _cancelToken,
      );
      return UpdateDownloadResult(
        filePath: savePath,
        action: path.extension(savePath).toLowerCase() == '.exe'
            ? DownloadedPackageAction.runInstaller
            : DownloadedPackageAction.openFolder,
      );
    } catch (e) {
      if (e.toString().contains('下载已取消')) {
        throw const UpdateDownloadCancelledException();
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
