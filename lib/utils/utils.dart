import 'dart:io';
import 'dart:math';
import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/http/dio/dio_request.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart'
    show getDownloadsDirectory, getTemporaryDirectory;
import 'package:logger/logger.dart';

class Utils {
  static Logger logger = Logger();
  static const double kMobileBreakpoint = 480;
  static const double kTabletBreakpoint = 1024;

  // --- 默认设计稿尺寸 ---
  static const Size kMobileDesignSize = Size(375, 812); // 手机主流尺寸
  static const Size kTabletDesignSize = Size(768, 1024); // 平板
  static const Size kDesktopDesignSize = Size(1440, 900); // 桌面端

  // 从URL参数中解析 m3u8/mp4
  static String decodeVideoSource(String iframeUrl) {
    var decodedUrl = Uri.decodeFull(iframeUrl);
    RegExp regExp = RegExp(r'(http[s]?://.*?\.m3u8)|(http[s]?://.*?\.mp4)',
        caseSensitive: false);

    Uri uri = Uri.parse(decodedUrl);
    Map<String, String> params = uri.queryParameters;

    String matchedUrl = iframeUrl;
    params.forEach((key, value) {
      if (regExp.hasMatch(value)) {
        matchedUrl = value;
        return;
      }
    });

    return Uri.encodeFull(matchedUrl);
  }

  // 获取随机UA
  static String getRandomUA() {
    final random = Random();
    String randomElement =
        Constants.userAgentList[random.nextInt(Constants.userAgentList.length)];
    return randomElement;
  }

  static bool? _isDocumentStartScriptSupported;

  /// 检查 Android WebView 是否支持 DOCUMENT_START_SCRIPT 特性
  static Future<void> checkWebViewFeatureSupport() async {
    if (Platform.isAndroid) {
      _isDocumentStartScriptSupported = await PlatformWebViewFeature.static()
          .isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT);
    }
  }

  static bool get isDocumentStartScriptSupported =>
      _isDocumentStartScriptSupported ?? false;

  // 根据屏幕宽度确定设计稿尺寸
  // static Size getDesignSize(BuildContext context) {
  //   double width = MediaQuery.of(context).size.width;
  //
  //   // 1. 桌面端 (Windows, MacOS, Web)
  //   if (kIsWeb || isDesktop) {
  //     // 如果窗口被用户拉得非常小，则回退到平板设计稿，避免字体缩到看不见
  //     if (width < kMobileBreakpoint) return kMobileDesignSize;
  //     if (width < kTabletBreakpoint) return kTabletDesignSize;
  //     return kDesktopDesignSize;
  //   }
  //
  //   // 2. 移动端 (iOS, Android)
  //   if (width <= kMobileBreakpoint) {
  //     return kMobileDesignSize;
  //   } else {
  //     return kTabletDesignSize;
  //   }
  // }

  static Future<void> downloadImage(String url, String name) async {
    try {
      final String time = DateTime.now().millisecondsSinceEpoch.toString();
      if (SystemUtil.isMobile) {
        /*
          移动端(保持到相册)
          检查并申请存储权限
        */
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          bool granted = await Gal.requestAccess();
          if (!granted) {
            Get.snackbar('提示', '存储权限被拒绝，无法保存图片', maxWidth: 500);
            throw Exception('存储权限被拒绝，无法保存图片');
          }
        }
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$time.jpg';
        await dioRequest.download(url, filePath);
        final bytes = await File(filePath).readAsBytes();
        await Gal.putImageBytes(bytes, name: '${name}_$time');
        await File(filePath).delete();
        Get.snackbar('提示', '图片已保存到相册', maxWidth: 500);
      } else {
        //桌面端(保持到下载目录)
        final dir = await getDownloadsDirectory();
        final filePath = '${dir?.path}/${name}_$time.jpg';
        await dioRequest.download(url, filePath);
        Logger().i('图片已保存到:$filePath');
        Get.snackbar('提示', '图片已保存到:$filePath', maxWidth: 500);
      }
    } catch (e) {
      Get.snackbar('提示', '保存图片失败:$e', maxWidth: 500);
      Logger().e('保存图片失败:$e');
    }
  }

  static Color generateDanmakuColor(int colorValue) {
    // 提取颜色分量
    int red = (colorValue >> 16) & 0xFF;
    int green = (colorValue >> 8) & 0xFF;
    int blue = colorValue & 0xFF;
    // 创建Color对象
    Color color = Color.fromARGB(255, red, green, blue);
    return color;
  }

  ///计算百分率
  static String calculatePercentage(int value, int total) {
    if (total <= 0) {
      return '0%';
    }
    final percentage = (value / total) * 100;
    if (percentage >= 100) {
      return '100%';
    }
    // 保留1位小数，如果小数部分为0则显示整数
    if (percentage % 1 == 0) {
      return '${percentage.toInt()}%';
    }
    return '${percentage.toStringAsFixed(1)}%';
  }

  static String buildShadersAbsolutePath(
      String baseDirectory, List<String> shaders) {
    List<String> absolutePaths = shaders.map((shader) {
      return path.join(baseDirectory, shader);
    }).toList();
    if (Platform.isWindows) {
      return absolutePaths.join(';');
    }
    return absolutePaths.join(':');
  }

  /// 比较两个版本号字符串
  /// 返回值: 1表示v1 > v2, -1表示v1 < v2, 0表示相等
  static int compareVersionNumbers(String v1, String v2) {
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
}
