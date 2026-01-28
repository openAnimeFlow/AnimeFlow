import 'dart:io';
import 'dart:typed_data';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart'
    show getDownloadsDirectory;
import 'package:window_manager/window_manager.dart';

/// 系统信息工具类
class SystemUtil {
  static final Battery _battery = Battery();
  static final Connectivity _connectivity = Connectivity();

  ///网络类型常量
  static const String  networkTypeNone = 'none';
  static const String  networkTypeWifi = 'wifi';
  static const String  networkTypeMobile = 'mobile';
  static const String  networkTypeEthernet = 'ethernet';
  static const String  networkTypeUnknown = 'unknown';

  /// 获取电池电量（0-100）
  static Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      return 0;
    }
  }

  /// 获取电池充电状态
  static Future<BatteryState> getBatteryState() async {
    try {
      return await _battery.batteryState;
    } catch (e) {
      return BatteryState.unknown;
    }
  }

  /// 获取电池状态流（监听电池状态变化）
  static Stream<BatteryState> get batteryStateStream =>
      _battery.onBatteryStateChanged;

  /// 获取当前时间字符串
  /// 返回格式：HH:MM:SS
  static String getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  /// 获取当前时间字符串
  /// 返回格式：HH:MM
  static String getCurrentTimeWithoutSeconds() {
    DateTime now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }


  static String getDevice() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isLinux) {
      return 'linux';
    } else if (Platform.isWindows) {
      return 'windows';
    } else {
      return 'unknown';
    }
  }

  /// 判断是否为桌面端
  static bool get isDesktop {
    return defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  ///判断是否为移动端
  static bool get isMobile {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  ///判断系统是否深色主题
  static bool isDarkTheme(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// 获取当前网络类型
  /// 返回：'wifi'、'mobile'、'ethernet'、'none' 或 'unknown'
  static Future<String> getNetworkType() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // connectivity_plus 返回 List<ConnectivityResult>
      // 通常取第一个结果，或者检查是否包含 wifi/mobile
      if (connectivityResult.isEmpty) {
        return networkTypeNone;
      }

      // 优先检查 WiFi
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        return networkTypeWifi;
      }
      
      // 检查移动网络
      if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return networkTypeMobile;
      }
      
      // 检查以太网
      if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        return networkTypeEthernet;
      }
      
      // 其他类型
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return networkTypeNone;
      }

      return networkTypeUnknown;
    } catch (e) {
      return networkTypeUnknown;
    }
  }

  /// 获取网络状态流（监听网络状态变化）
  static Stream<List<ConnectivityResult>> get networkStateStream =>
      _connectivity.onConnectivityChanged;


  /// 进入全屏显示
  static Future<void> enterFullScreen() async {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      await windowManager.setFullScreen(true);
      return;
    }
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    // Android 多窗口模式下不锁定方向
    // 简化处理，如果需要可以添加 device_info_plus 来检测
    // 横屏
    await setLandscape();
  }

  /// 退出全屏显示
  static Future<void> exitFullScreen() async {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      await windowManager.setFullScreen(false);
    }
    late SystemUiMode mode = SystemUiMode.edgeToEdge;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // 简化处理，直接使用 edgeToEdge
        // 如果需要更精确的控制，可以添加 device_info_plus 来检测 Android 版本
        mode = SystemUiMode.edgeToEdge;
      }
      await SystemChrome.setEnabledSystemUIMode(mode);
    } catch (_) {}

    await restorePortraitOrientation();
  }

  /// 恢复竖屏方向
  static Future<void> restorePortraitOrientation() async {
    if (isMobile) {
      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight
        ]);
      } catch (e) {
        Logger().e('恢复竖屏方向失败: $e');
      }
    }
  }

  ///设置横屏
  static Future<void> setLandscape() async {
    if (isMobile) {
      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight
        ]);
      } catch (e) {
        Logger().e('设置横屏方向失败: $e');
      }
    }
  }

  /// 保存图片字节数据
  /// [bytes] 图片字节数据
  /// [name] 图片名称（不含扩展名）
  static Future<void> saveImageBytes(Uint8List bytes, {String name = 'screenshot'}) async {
    try {
      final String time = DateTime.now().millisecondsSinceEpoch.toString();
      
      if (isMobile) {
        // 移动端(保存到相册)
        // 检查并申请存储权限
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          bool granted = await Gal.requestAccess();
          if (!granted) {
            Get.snackbar('提示', '存储权限被拒绝，无法保存图片', maxWidth: 500);
            throw Exception('存储权限被拒绝，无法保存图片');
          }
        }
        
        await Gal.putImageBytes(bytes, name: '${name}_$time');
        Get.snackbar('提示', '图片已保存到相册', maxWidth: 500);
      } else {
        // 桌面端(保存到下载目录)
        final dir = await getDownloadsDirectory();
        final filePath = '${dir?.path}/${name}_$time.png';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        Logger().i('图片已保存到:$filePath');
        Get.snackbar('提示', '图片已保存到:$filePath', maxWidth: 500);
      }
    } catch (e) {
      Get.snackbar('提示', '保存图片失败:$e', maxWidth: 500);
      Logger().e('保存图片失败:$e');
    }
  }

}

