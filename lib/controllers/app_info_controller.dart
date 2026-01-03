import 'package:anime_flow/http/requests/request.dart';
import 'package:anime_flow/models/enums/version_type.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfoController extends GetxController {
  // 应用信息
  final Rx<PackageInfo?> appInfo = Rx<PackageInfo?>(null);

  // 加载状态
  final RxBool isLoading = true.obs;

  // 错误信息
  final RxString error = ''.obs;

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

        List<String> urlList = getDownloadUrl(downloadInfo);

        if (urlList.isEmpty) {
          Get.snackbar("检查更新", "未找到对应平台的下载地址", maxWidth: 500);
          return VersionType.localNewer;
        }

        // 默认选择第一条
        int selectedIndex = 0;

        Get.dialog(
          AlertDialog(
            title: const Text("检查更新"),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(VersionType.newVersion.message),
                    const SizedBox(height: 16),
                    if (urlList.length > 1)
                      Text(
                        "请选择下载地址:",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 8),
                    ...List.generate(urlList.length, (index) {
                      final url = urlList[index];
                      final isSelected = index == selectedIndex;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                )
                              else
                                Icon(
                                  Icons.radio_button_unchecked,
                                  color: Theme.of(context).colorScheme.outline,
                                  size: 20,
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  url,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: const Text("稍后更新"),
              ),
              TextButton(
                // TODO: 实际的应用内下载安装
                onPressed: () async {
                  final selectedUrl = urlList[selectedIndex];
                  Get.log('选中的下载地址: $selectedUrl');
                  final authUrl = Uri.parse(selectedUrl);
                  if (await canLaunchUrl(authUrl)) {
                    await launchUrl(authUrl);
                  } else {
                    Logger().e('无法打开链接:$authUrl');
                    throw 'Could not launch ';
                  }
                },
                child: const Text("立即更新"),
              ),
            ],
          ),
        );
        return VersionType.newVersion; // 远程版本更高，有新版本
      } else if (comparison < 0) {
        return VersionType.localNewer; // 本地版本更高（开发版本）
      } else {
        Get.snackbar("检查更新", VersionType.sameVersion.message, maxWidth: 500);
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
  List<String> getDownloadUrl(List<Map<String, dynamic>> assets) {
    final platform = Utils.getDevice();
    final List<String> urlList = [];

    for (var asset in assets) {
      final name = asset['name']?.toString() ?? '';
      final url = asset['browser_download_url']?.toString();

      if (url == null || url.isEmpty) continue;

      switch (platform) {
        case 'android':
          if (name.toLowerCase().contains('android')) {
            urlList.add(url);
          }
          break;
        case 'ios':
          if (name.toLowerCase().contains('ios')) {
            urlList.add(url);
          }
          break;
        case 'macos':
          if (name.toLowerCase().contains('macos') ||
              name.toLowerCase().contains('mac')) {
            urlList.add(url);
          }
          break;
        case 'windows':
          if (name.toLowerCase().contains('windows') ||
              name.toLowerCase().contains('win')) {
            urlList.add(url);
          }
          break;
        case 'linux':
          if (name.toLowerCase().contains('linux')) {
            urlList.add(url);
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
}
