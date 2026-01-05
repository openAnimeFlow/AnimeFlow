import 'dart:io';

import 'package:anime_flow/http/requests/request.dart';
import 'package:anime_flow/models/enums/version_type.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart' show getDownloadsDirectory;
import 'package:path/path.dart' as path;

import 'apply_updates_controller.dart';
import 'apply_updates_view.dart';

class AppInfoController extends GetxController {
  // 应用信息
  final Rx<PackageInfo?> appInfo = Rx<PackageInfo?>(null);

  // 加载状态
  final RxBool isLoading = true.obs;

  // 错误信息
  final RxString error = ''.obs;

  // 下载进度
  final RxDouble downloadProgress = 0.0.obs;
  final RxInt receivedBytes = 0.obs;
  final RxInt totalBytes = 0.obs;
  final RxBool isDownloading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAppInfo();
  }

  /// 加载应用信息
  Future<void> _loadAppInfo() async {
    try {
      isLoading.value = true;
      error.value = '';

      final info = await PackageInfo.fromPlatform();
      appInfo.value = info;
    } catch (e) {
      error.value = e.toString();
      Get.log('加载应用信息失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 重新加载应用信息
  Future<void> reload() async {
    await _loadAppInfo();
  }

  ///检查版本更新
  Future<VersionType> compareVersion() async {
    try {
      final release = await Request.getReleases();
      final remoteVersion = release['tag_name']?.toString();
      if (remoteVersion == null || remoteVersion.isEmpty) {
        Get.log('无法获取远程版本号');
        return VersionType.localNewer;
      }

      final String localVersion = version;

      // 移除远程版本号的 'v' 前缀
      String cleanRemoteVersion = remoteVersion.startsWith('v')
          ? remoteVersion.substring(1)
          : remoteVersion;

      // 比较版本号
      int comparison = _compareVersionNumbers(cleanRemoteVersion, localVersion);

      if (comparison > 0) {
        final assets = release['assets'];
        if (assets == null || assets is! List) {
          Get.log('assets 数据格式错误');
          return VersionType.localNewer;
        }

        final downloadInfo = assets
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        List<DownloadInfo> download = getDownloadInfo(downloadInfo);

        if (download.isEmpty) {
          Get.snackbar("检查更新", "未找到对应平台的下载地址", maxWidth: 500);
          return VersionType.localNewer;
        }

        // 重置下载状态
        isDownloading.value = false;
        downloadProgress.value = 0.0;
        receivedBytes.value = 0;
        totalBytes.value = 0;

        ApplyUpdatesController? updateController;
        final body = release['body']?.toString() ?? '';
        Get.dialog(
          barrierDismissible: false,
          ApplyUpdatesView(
            download: download,
            body: body,
            onStartDownload: (downloadUrl, fileName) async {
              // 开始下载
              isDownloading.value = true;
              downloadProgress.value = 0.0;
              receivedBytes.value = 0;
              totalBytes.value = 0;

              updateController = ApplyUpdatesFactory.getController();

              try {
                await updateController!.applyUpdates(
                  downloadUrl,
                  fileName: fileName,
                  onProgress: (received, total) {
                    receivedBytes.value = received;
                    totalBytes.value = total;
                    if (total > 0) {
                      downloadProgress.value = received / total;
                    }
                  },
                );
                
                // 关闭下载进度对话框
                Get.back();
                
                // Windows 平台下载完成后显示完成对话框
                if (Platform.isWindows) {
                  final tempDir = await getDownloadsDirectory();
                  final savePath = path.join(tempDir!.path, fileName);
                  _showWindowsDownloadCompleteDialog(savePath);
                }
              } catch (e) {
                // 如果是取消操作，不显示错误提示
                if (!e.toString().contains('下载已取消')) {
                  Get.back();
                  Get.snackbar(
                    "下载失败",
                    "更新下载失败: $e",
                    maxWidth: 500,
                  );
                }
              } finally {
                isDownloading.value = false;
                updateController = null;
              }
            },
            onCancelDownload: () {
              // 取消下载
              updateController?.cancelDownload();
              isDownloading.value = false;
              downloadProgress.value = 0.0;
              receivedBytes.value = 0;
              totalBytes.value = 0;
              Get.snackbar(
                "下载已取消",
                "已取消下载",
                maxWidth: 500,
              );
            },
          ),
        );
        return VersionType.newVersion; // 远程版本更高，有新版本
      } else if (comparison < 0) {
        return VersionType.localNewer; // 本地版本更高（开发版本）
      } else {
        return VersionType.sameVersion; // 版本相同
      }
    } catch (e) {
      Logger().e('版本比较失败: $e');
      return VersionType.localNewer;
    }
  }

  /// 比较两个版本号字符串
  /// 返回值: 1表示v1 > v2, -1表示v1 < v2, 0表示相等
  int _compareVersionNumbers(String v1, String v2) {
    List<int> parseVersion(String version) {
      return version.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    }

    List<int> version1 = parseVersion(v1);
    List<int> version2 = parseVersion(v2);

    // 比较主版本号、次版本号、修订号
    for (int i = 0; i < 3; i++) {
      if (i < version1.length && i < version2.length) {
        if (version1[i] > version2[i]) return 1;
        if (version1[i] < version2[i]) return -1;
      } else if (i < version1.length) {
        return version1[i] > 0 ? 1 : -1;
      } else if (i < version2.length) {
        return version2[i] > 0 ? -1 : 1;
      }
    }
    return 0;
  }

  ///根据平台获取下载地址
  List<DownloadInfo> getDownloadInfo(List<Map<String, dynamic>> assets) {
    final platform = Utils.getDevice();
    final List<DownloadInfo> urlList = [];

    for (var asset in assets) {
      final name = asset['name']?.toString() ?? '';
      final url = asset['browser_download_url']?.toString();

      if (url == null || url.isEmpty) continue;

      switch (platform) {
        case 'android':
          if (name.toLowerCase().contains('android')) {
            urlList.add(DownloadInfo.fromJson(asset));
          }
          break;
        case 'ios':
          if (name.toLowerCase().contains('ios')) {
            urlList.add(DownloadInfo.fromJson(asset));
          }
          break;
        case 'macos':
          if (name.toLowerCase().contains('macos') ||
              name.toLowerCase().contains('mac')) {
            urlList.add(DownloadInfo.fromJson(asset));
          }
          break;
        case 'windows':
          if (name.toLowerCase().contains('windows') ||
              name.toLowerCase().contains('win')) {
            urlList.add(DownloadInfo.fromJson(asset));
          }
          break;
        case 'linux':
          if (name.toLowerCase().contains('linux')) {
            urlList.add(DownloadInfo.fromJson(asset));
          }
          break;
      }
    }

    return urlList;
  }


  /// 获取版本号
  String get version => appInfo.value?.version ?? '未知';

  /// 获取构建号
  String get buildNumber => appInfo.value?.buildNumber ?? '未知';

  /// 获取应用名称
  String get appName => appInfo.value?.appName ?? '未知';

  /// 获取包名
  String get packageName => appInfo.value?.packageName ?? '未知';

  /// 显示 Windows 平台下载完成对话框
  void _showWindowsDownloadCompleteDialog(String savePath) {
    Get.dialog(
      barrierDismissible: false,
      Builder(
        builder: (context) => AlertDialog(
          title: const Text('下载完成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('安装包已下载完成'),
              const SizedBox(height: 8),
              SelectableText(
                savePath,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await Process.start(
                    'explorer.exe',
                    ['/select,', savePath],
                    runInShell: true,
                  );
                  Get.back();
                } catch (e) {
                  Get.back();
                  Get.snackbar(
                    '打开失败',
                    '无法打开文件管理器: $e',
                    maxWidth: 500,
                  );
                }
              },
              child: const Text('打开安装包文件夹'),
            ),
          ],
        ),
      ),
    );
  }
}

class DownloadInfo {
  final String url;
  final String fileName;
  final int size;

  DownloadInfo(this.url, this.fileName, this.size);

  factory DownloadInfo.fromJson(Map<String, dynamic> json) {
    return DownloadInfo(
      json['browser_download_url'] as String,
      json['name'] as String,
      json['size'] as int,
    );
  }
}