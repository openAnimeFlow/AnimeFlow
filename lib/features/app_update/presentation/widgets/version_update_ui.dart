import 'dart:io';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/app_update/application/apply_updates_controller.dart';
import 'package:anime_flow/shared/models/download_info.dart';
import 'package:anime_flow/shared/models/enums/version_type.dart';
import 'package:anime_flow/shared/models/version_check_result.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/features/app_update/presentation/widgets/apply_updates_view.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';

/// 开始下载，成功时返回 Windows 安装包路径
typedef OnVersionStartDownload = Future<String?> Function(
  DownloadInfo downloadInfo,
);

typedef OnVersionCancelDownload = void Function();

/// 根据版本检查结果展示提示或更新弹窗
Future<void> handleVersionCheckResult(
  BuildContext context,
  VersionCheckResult result, {
  required OnVersionStartDownload onStartDownload,
  required OnVersionCancelDownload onCancelDownload,
  bool notifyWhenUpToDate = false,
}) async {
  if (result.hasToast) {
    NotificationToast.show(
      result.toastMessage!,
      title: result.toastTitle!,
      maxWidth: 500,
    );
  }

  switch (result.type) {
    case VersionType.newVersion:
      final updateInfo = result.updateInfo;
      if (updateInfo != null && context.mounted) {
        await showVersionUpdateDialog(
          context,
          updateInfo: updateInfo,
          onStartDownload: onStartDownload,
          onCancelDownload: onCancelDownload,
        );
      }
      break;
    case VersionType.sameVersion:
      if (notifyWhenUpToDate) {
        final l10n = AppLocalizations.of(context);
        NotificationToast.show(l10n.latestVersion, title: l10n.checkForUpdates);
      }
      break;
    case VersionType.localNewer:
      break;
  }
}

Future<void> showVersionUpdateDialog(
  BuildContext context, {
  required VersionUpdateInfo updateInfo,
  required OnVersionStartDownload onStartDownload,
  required OnVersionCancelDownload onCancelDownload,
}) async {
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => ApplyUpdatesView(
      setting: Storage.setting,
      download: updateInfo.download,
      body: updateInfo.body,
      onStartDownload: (downloadUrl, fileName) async {
        final downloadInfo = updateInfo.download.firstWhere(
          (info) => info.url == downloadUrl && info.fileName == fileName,
          orElse: () => updateInfo.download[0],
        );

        try {
          final savePath = await onStartDownload(downloadInfo);

          if (dialogContext.mounted) {
            Navigator.of(dialogContext, rootNavigator: true).pop();
          }

          if (savePath != null && context.mounted) {
            await showWindowsDownloadCompleteDialog(context, savePath);
          }
        } catch (e) {
          if (e is UpdateDownloadCancelledException) {
            return;
          }
          if (dialogContext.mounted) {
            Navigator.of(dialogContext, rootNavigator: true).pop();
          }
          NotificationToast.show(
            l10n.updateDownloadFailed(e.toString()),
            title: l10n.downloadFailed,
            maxWidth: 500,
          );
        }
      },
      onCancelDownload: () {
        onCancelDownload();
        final l10n = AppLocalizations.of(context);
        NotificationToast.show(l10n.downloadCancelledMessage,
            title: l10n.downloadCancelled, maxWidth: 500);
      },
    ),
  );
}

Future<void> showWindowsDownloadCompleteDialog(
  BuildContext context,
  String savePath,
) async {
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.downloadComplete),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.packageDownloaded),
          const SizedBox(height: 8),
          SelectableText(
            savePath,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () async {
            try {
              await Process.start(
                'explorer.exe',
                ['/select,', savePath],
                runInShell: true,
              );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            } catch (e) {
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              NotificationToast.show(
                l10n.openFileManagerFailed(e.toString()),
                title: l10n.openFailed,
                maxWidth: 500,
              );
            }
          },
          child: Text(l10n.openPackageFolder),
        ),
      ],
    ),
  );
}
