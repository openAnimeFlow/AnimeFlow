import 'dart:io';

import 'package:anime_flow/features/app/apply_updates_controller.dart';
import 'package:anime_flow/models/download_info.dart';
import 'package:anime_flow/models/enums/version_type.dart';
import 'package:anime_flow/models/version_check_result.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/widget/apply_updates_view.dart';
import 'package:anime_flow/widget/notification_toast.dart';
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
      result.toastTitle!,
      result.toastMessage!,
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
        NotificationToast.show('检查更新', VersionType.sameVersion.message);
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
            '下载失败',
            '更新下载失败: $e',
            maxWidth: 500,
          );
        }
      },
      onCancelDownload: () {
        onCancelDownload();
        NotificationToast.show('下载已取消', '已取消下载', maxWidth: 500);
      },
    ),
  );
}

Future<void> showWindowsDownloadCompleteDialog(
  BuildContext context,
  String savePath,
) async {
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
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
              color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
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
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            } catch (e) {
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              NotificationToast.show(
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
  );
}
