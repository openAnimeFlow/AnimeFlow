import 'dart:io';

import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/features/app/app_info_state.dart';
import 'package:anime_flow/features/app/app_provider_container.dart';
import 'package:anime_flow/features/app/apply_updates_controller.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/requests/request.dart';
import 'package:anime_flow/models/download_info.dart';
import 'package:anime_flow/models/enums/version_type.dart';
import 'package:anime_flow/models/version_check_result.dart';
import 'package:anime_flow/models/version_download_state.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' show getDownloadsDirectory;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_info_provider.g.dart';

@Riverpod(keepAlive: true)
String appVersion(Ref ref) {
  final appInfo = ref.watch(appInfoProvider);
  return appInfo.packageInfo?.version ?? appPackageInfo?.version ?? '1.0.0';
}

@Riverpod(keepAlive: true)
class AppInfo extends _$AppInfo {
  ApplyUpdatesController? _updateController;

  @override
  AppInfoState build() {
    final packageInfo = appPackageInfo;
    if (packageInfo != null) {
      return AppInfoState(packageInfo: packageInfo, isLoading: false);
    }
    Future.microtask(_loadPackageInfo);
    return const AppInfoState();
  }

  Future<void> reload() => _loadPackageInfo();

  /// 版本检查
  Future<void> triggerStartupVersionCheck() async {
    if (state.hasTriggeredStartupCheck) return;

    state = state.copyWith(hasTriggeredStartupCheck: true);

    final autoUpdate = Storage.setting.get(
      StorageKey.autoUpdateKey,
      defaultValue: true,
    );
    if (!autoUpdate) return;

    final result = await checkVersion();
    state = state.copyWith(pendingStartupVersionResult: result);
  }

  void consumeStartupVersionResult() {
    if (state.pendingStartupVersionResult == null) return;
    state = state.copyWith(clearPendingStartupVersionResult: true);
  }

  Future<void> _loadPackageInfo() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final info = await PackageInfo.fromPlatform();
      appPackageInfo = info;
      state = state.copyWith(packageInfo: info, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      LiggLogger().e('加载应用信息失败: $e');
    }
  }

  Future<VersionCheckResult> checkVersion() async {
    try {
      final release = await Request.getResources<Map<String, dynamic>>(
          CommonApi.githubApi + CommonApi.animeFlowVersion);
      final remoteVersion = release['tag_name']?.toString();
      if (remoteVersion == null || remoteVersion.isEmpty) {
        return const VersionCheckResult(type: VersionType.localNewer);
      }

      final String localVersion = state.version;

      final cleanRemoteVersion = remoteVersion.startsWith('v')
          ? remoteVersion.substring(1)
          : remoteVersion;

      final comparison =
          Utils.compareVersionNumbers(cleanRemoteVersion, localVersion);

      if (comparison > 0) {
        final assets = release['assets'];
        final htmlUrl = release['html_url']?.toString();
        if (assets == null || assets is! List) {
          return const VersionCheckResult(type: VersionType.localNewer);
        }

        final downloadInfo = assets
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        final download = _getDownloadInfo(downloadInfo, htmlUrl ?? '');

        if (download.isEmpty) {
          return const VersionCheckResult(
            type: VersionType.localNewer,
            toastTitle: '检查更新',
            toastMessage: '未找到对应平台的下载地址',
          );
        }

        _resetDownloadState();

        final body = release['body']?.toString() ?? '';
        return VersionCheckResult(
          type: VersionType.newVersion,
          updateInfo: VersionUpdateInfo(download: download, body: body),
        );
      } else if (comparison < 0) {
        return const VersionCheckResult(type: VersionType.localNewer);
      } else {
        return const VersionCheckResult(type: VersionType.sameVersion);
      }
    } catch (e) {
      LiggLogger().e('版本比较失败: $e');
      return const VersionCheckResult(type: VersionType.localNewer);
    }
  }

  Future<String?> performUpdateDownload(DownloadInfo downloadInfo) async {
    state = state.copyWith(
      download: const VersionDownloadState(isDownloading: true),
    );

    _updateController = ApplyUpdatesFactory.getController();

    try {
      await _updateController!.applyUpdates(
        downloadInfo: downloadInfo,
        onProgress: (received, total) {
          state = state.copyWith(
            download: VersionDownloadState(
              isDownloading: true,
              receivedBytes: received,
              totalBytes: total,
              progress: total > 0 ? received / total : 0,
            ),
          );
        },
      );

      if (Platform.isWindows) {
        final tempDir = await getDownloadsDirectory();
        return path.join(tempDir!.path, downloadInfo.fileName);
      }
      return null;
    } on UpdateDownloadCancelledException {
      rethrow;
    } finally {
      _resetDownloadState();
      _updateController = null;
    }
  }

  void cancelUpdateDownload() {
    _updateController?.cancelDownload();
    _resetDownloadState();
  }

  void _resetDownloadState() {
    state = state.copyWith(download: VersionDownloadState.idle);
  }

  List<DownloadInfo> _getDownloadInfo(
    List<Map<String, dynamic>> assets,
    String htmlUrl,
  ) {
    final platform = SystemUtil.getDevice();
    final List<DownloadInfo> urlList = [];

    for (var asset in assets) {
      final name = asset['name']?.toString() ?? '';
      final url = asset['browser_download_url']?.toString();

      if (url == null || url.isEmpty) continue;

      switch (platform) {
        case 'android':
          if (name.toLowerCase().contains('android')) {
            urlList.add(DownloadInfo.fromJson(asset, htmlUrl));
          }
          break;
        case 'ios':
          if (name.toLowerCase().contains('ios')) {
            urlList.add(DownloadInfo.fromJson(asset, htmlUrl));
          }
          break;
        case 'macos':
          if (name.toLowerCase().contains('macos') ||
              name.toLowerCase().contains('mac')) {
            urlList.add(DownloadInfo.fromJson(asset, htmlUrl));
          }
          break;
        case 'windows':
          if (name.toLowerCase().contains('windows') ||
              name.toLowerCase().contains('win')) {
            urlList.add(DownloadInfo.fromJson(asset, htmlUrl));
          }
          break;
        case 'linux':
          if (name.toLowerCase().contains('linux')) {
            urlList.add(DownloadInfo.fromJson(asset, htmlUrl));
          }
          break;
      }
    }

    return urlList;
  }
}
