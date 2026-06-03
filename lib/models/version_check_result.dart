import 'package:anime_flow/models/download_info.dart';
import 'package:anime_flow/models/enums/version_type.dart';

class VersionUpdateInfo {
  final List<DownloadInfo> download;
  final String body;

  const VersionUpdateInfo({
    required this.download,
    required this.body,
  });
}

class VersionCheckResult {
  final VersionType type;
  final VersionUpdateInfo? updateInfo;
  final String? toastTitle;
  final String? toastMessage;

  const VersionCheckResult({
    required this.type,
    this.updateInfo,
    this.toastTitle,
    this.toastMessage,
  });

  bool get hasToast => toastTitle != null && toastMessage != null;
}
