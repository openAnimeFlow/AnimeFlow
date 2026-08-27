import 'dart:io';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class DownloadForegroundService {
  static const _serviceId = 4101;
  static const _pauseAllButtonId = 'pause_all';
  static Future<void> _operation = Future<void>.value();
  static Locale? _localizationLocale;
  static Future<AppLocalizations>? _localization;
  static bool _notificationPermissionRequested = false;
  static void Function()? onPauseAll;

  static Future<void> initialize() async {
    if (!Platform.isAndroid || FlutterForegroundTask.isInitialized) {
      return;
    }

    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'anime_flow_downloads',
        channelName: 'AnimeFlow downloads',
        channelDescription: 'Shows the progress of video downloads.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        allowWakeLock: true,
        allowWifiLock: true,
        allowAutoRestart: false,
      ),
    );
  }

  static Future<void> sync({
    required int activeTasks,
    required int completedTasks,
    required int totalTasks,
    required double speed,
    required Locale locale,
  }) {
    _operation = _operation.then((_) async {
      if (!Platform.isAndroid) {
        return;
      }
      if (activeTasks == 0) {
        if (await FlutterForegroundTask.isRunningService) {
          await FlutterForegroundTask.stopService();
        }
        return;
      }

      if (!_notificationPermissionRequested) {
        _notificationPermissionRequested = true;
        final permission =
            await FlutterForegroundTask.checkNotificationPermission();
        if (permission != NotificationPermission.granted) {
          await FlutterForegroundTask.requestNotificationPermission();
        }
      }

      final l10n = await _loadLocalization(locale);
      final text = l10n.downloadNotificationStatus(
        activeTasks,
        completedTasks,
        totalTasks,
        _formatSpeed(speed),
      );
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: l10n.downloadNotificationTitle,
          notificationText: text,
          notificationButtons: [
            NotificationButton(
              id: _pauseAllButtonId,
              text: l10n.downloadPauseAll,
            ),
          ],
        );
      } else {
        await FlutterForegroundTask.startService(
          serviceId: _serviceId,
          serviceTypes: const [ForegroundServiceTypes.dataSync],
          notificationTitle: l10n.downloadNotificationTitle,
          notificationText: text,
          notificationButtons: [
            NotificationButton(
              id: _pauseAllButtonId,
              text: l10n.downloadPauseAll,
            ),
          ],
          notificationInitialRoute: '/download',
          callback: _startCallback,
        );
      }
    }).catchError((_) {});
    return _operation;
  }

  static Future<AppLocalizations> _loadLocalization(Locale locale) {
    if (_localization == null || _localizationLocale != locale) {
      _localizationLocale = locale;
      _localization = AppLocalizations.delegate.load(locale);
    }
    return _localization!;
  }

  static void _onTaskData(Object data) {
    if (data is Map && data['action'] == _pauseAllButtonId) {
      onPauseAll?.call();
    }
  }

  static String _formatSpeed(double speed) {
    if (speed < 1024) {
      return '${speed.toStringAsFixed(0)} B/s';
    }
    if (speed < 1024 * 1024) {
      return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_DownloadTaskHandler());
}

class _DownloadTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'pause_all') {
      FlutterForegroundTask.sendDataToMain({'action': 'pause_all'});
    }
  }
}
