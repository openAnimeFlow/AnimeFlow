import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/features/app_update/application/app_info_state.dart';
import 'package:anime_flow/features/app_update/application/apply_updates_controller.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/download_info.dart';
import 'package:anime_flow/shared/models/github_release.dart';
import 'package:anime_flow/shared/models/enums/version_type.dart';
import 'package:anime_flow/shared/models/version_check_result.dart';
import 'package:anime_flow/shared/models/version_download_state.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_info_provider.g.dart';

PackageInfo? appPackageInfo;

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
      final release = await FlowApi.getLatestRelease();
      final remoteVersion = release.tagName;
      if (remoteVersion.isEmpty) {
        return const VersionCheckResult(type: VersionType.localNewer);
      }

      final String localVersion = state.version;

      final cleanRemoteVersion = remoteVersion.toLowerCase().startsWith('v')
          ? remoteVersion.substring(1)
          : remoteVersion;

      final comparison =
          Utils.compareVersionNumbers(cleanRemoteVersion, localVersion);

      if (comparison > 0) {
        if (release.assets.isEmpty) {
          return const VersionCheckResult(type: VersionType.localNewer);
        }

        final download =
            await _getDownloadInfo(release.assets, release.htmlUrl);

        if (download.isEmpty) {
          return const VersionCheckResult(
            type: VersionType.localNewer,
            toastTitle: '检查更新',
            toastMessage: '未找到对应平台的下载地址',
          );
        }

        _resetDownloadState();

        return VersionCheckResult(
          type: VersionType.newVersion,
          updateInfo: VersionUpdateInfo(download: download, body: release.body),
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

  Future<UpdateDownloadResult?> performUpdateDownload(
      DownloadInfo downloadInfo) async {
    _updateController = ApplyUpdatesFactory.getController();
    final controller = _updateController!;
    if (controller.supportsInAppDownload) {
      state = state.copyWith(
        download: const VersionDownloadState(isDownloading: true),
      );
    }

    try {
      return await controller.applyUpdates(
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
    } on UpdateDownloadCancelledException {
      rethrow;
    } finally {
      _resetDownloadState();
      _updateController = null;
    }
  }

  Future<void> openDownloadedPackage(String filePath) async {
    await ApplyUpdatesFactory.getController().openDownloadedPackage(filePath);
  }

  void cancelUpdateDownload() {
    _updateController?.cancelDownload();
    _resetDownloadState();
  }

  void _resetDownloadState() {
    state = state.copyWith(download: VersionDownloadState.idle);
  }

  Future<List<DownloadInfo>> _getDownloadInfo(
    List<GithubReleaseAsset> assets,
    String htmlUrl,
  ) async {
    final platform = SystemUtil.getDevice();
    final List<DownloadInfo> urlList = [];

    for (var asset in assets) {
      final name = asset.name;
      final url = asset.browserDownloadUrl;

      if (url.isEmpty) continue;

      switch (platform) {
        case 'android':
          if (name.toLowerCase().contains('android')) {
            urlList.add(DownloadInfo(url, name, asset.size, htmlUrl));
          }
          break;
        case 'ios':
          if (name.toLowerCase().contains('ios')) {
            urlList.add(DownloadInfo(url, name, asset.size, htmlUrl));
          }
          break;
        case 'macos':
          if (name.toLowerCase().contains('macos') ||
              name.toLowerCase().contains('mac')) {
            urlList.add(DownloadInfo(url, name, asset.size, htmlUrl));
          }
          break;
        case 'windows':
          if (name.toLowerCase().contains('windows') ||
              name.toLowerCase().contains('win')) {
            urlList.add(DownloadInfo(url, name, asset.size, htmlUrl));
          }
          break;
        case 'linux':
          if (name.toLowerCase().contains('linux')) {
            urlList.add(DownloadInfo(url, name, asset.size, htmlUrl));
          }
          break;
      }
    }

    return await ApplyUpdatesFactory.getController()
        .prioritizeDownloads(urlList);
  }
}
