import 'dart:io';

import 'package:anime_flow/features/app_update/application/apply_updates_controller.dart';
import 'package:anime_flow/core/network/api/api.dart';
import 'package:anime_flow/shared/models/download_info.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart'
    show getExternalStorageDirectory;

/// Android 平台更新实现
class ApplyUpdatesAndroidController implements ApplyUpdatesController {
  CancelToken? _cancelToken;

  @override
  bool get supportsInAppDownload => true;

  @override
  Future<List<DownloadInfo>> prioritizeDownloads(
    List<DownloadInfo> downloads,
  ) async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final abi = androidInfo.supportedAbis
        .map((value) => value.toLowerCase())
        .firstWhere(
          (value) =>
              value.contains('arm64') ||
              value.contains('armeabi') ||
              value.contains('x86'),
          orElse: () => '',
        );

    final priorities = switch (abi) {
      final value when value.contains('arm64') => const [
          'arm64',
          'v7a',
          'x86',
        ],
      final value when value.contains('armeabi') => const [
          'v7a',
          'arm64',
          'x86',
        ],
      final value when value.contains('x86') => const [
          'x86',
          'arm64',
          'v7a',
        ],
      _ => const <String>[],
    };

    if (priorities.isEmpty) return downloads;

    final indexedDownloads = downloads.asMap().entries.toList();
    indexedDownloads.sort((a, b) {
      final aPriority = _packagePriority(a.value.fileName, priorities);
      final bPriority = _packagePriority(b.value.fileName, priorities);
      return aPriority.compareTo(bPriority);
    });
    return indexedDownloads.map((entry) => entry.value).toList();
  }

  int _packagePriority(String fileName, List<String> priorities) {
    final normalizedName = fileName.toLowerCase();
    for (var index = 0; index < priorities.length; index++) {
      if (normalizedName.contains(priorities[index])) return index;
    }
    return priorities.length;
  }

  @override
  Future<void> openDownloadedPackage(String filePath) async {
    throw UnsupportedError('Android 不支持此操作');
  }

  @override
  Future<UpdateDownloadResult?> applyUpdates({
    required DownloadInfo downloadInfo,
    void Function(int received, int total)? onProgress,
  }) async {
    _cancelToken = CancelToken();

    try {
      final dir = await getExternalStorageDirectory();
      final savePath = '${dir!.path}/${downloadInfo.fileName}';
      await Api.downloadFile(
        downloadInfo.url,
        savePath,
        onReceiveProgress: (received, total) {
          onProgress?.call(received, total);
        },
        cancelToken: _cancelToken,
      );

      final result = await OpenFile.open(File(savePath).path);
      if (result.type != ResultType.done) {
        LiggLogger().e('无法打开安装程序，请检查是否授予了安装权限');
        return null;
      }
      return null;
    } catch (e) {
      // 如果是取消操作，不抛出异常
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
