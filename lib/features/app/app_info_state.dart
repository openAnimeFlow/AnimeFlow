import 'package:anime_flow/models/version_download_state.dart';
import 'package:anime_flow/models/version_check_result.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoState {
  const AppInfoState({
    this.packageInfo,
    this.isLoading = true,
    this.error = '',
    this.download = VersionDownloadState.idle,
    this.pendingStartupVersionResult,
    this.hasTriggeredStartupCheck = false,
  });

  final PackageInfo? packageInfo;
  final bool isLoading;
  final String error;
  final VersionDownloadState download;
  final VersionCheckResult? pendingStartupVersionResult;
  final bool hasTriggeredStartupCheck;

  String get version => packageInfo?.version ?? '未知';

  String get buildNumber => packageInfo?.buildNumber ?? '未知';

  String get appName => packageInfo?.appName ?? '未知';

  String get packageName => packageInfo?.packageName ?? '未知';

  AppInfoState copyWith({
    PackageInfo? packageInfo,
    bool? isLoading,
    String? error,
    VersionDownloadState? download,
    VersionCheckResult? pendingStartupVersionResult,
    bool clearPendingStartupVersionResult = false,
    bool? hasTriggeredStartupCheck,
    bool clearError = false,
  }) {
    return AppInfoState(
      packageInfo: packageInfo ?? this.packageInfo,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? '' : (error ?? this.error),
      download: download ?? this.download,
      pendingStartupVersionResult: clearPendingStartupVersionResult
          ? null
          : (pendingStartupVersionResult ?? this.pendingStartupVersionResult),
      hasTriggeredStartupCheck:
          hasTriggeredStartupCheck ?? this.hasTriggeredStartupCheck,
    );
  }
}
