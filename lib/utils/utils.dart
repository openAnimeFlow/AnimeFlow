import 'dart:io';
import 'dart:math';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:path/path.dart' as path;

class Utils {
  static LiggLogger logger = LiggLogger();
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

  /// 获取随机UA
  static String getRandomUA() {
    final random = Random();
    return userAgentList[random.nextInt(userAgentList.length)];
  }

  /// 获取随机Accept-Language
  static String getRandomAcceptedLanguage() {
    final random = Random();
    return acceptLanguageList[random.nextInt(acceptLanguageList.length)];
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

  static Color generateDanmakuColor(int colorValue) {
    // 提取颜色分量
    int red = (colorValue >> 16) & 0xFF;
    int green = (colorValue >> 8) & 0xFF;
    int blue = colorValue & 0xFF;
    // 创建Color对象
    Color color = Color.fromARGB(255, red, green, blue);
    return color;
  }

  /// 将 [color] 转为十进制 RGB 整数**：`R<<16 | G<<8 | B`（0～16777215）。
  static int colorToDecimalRgb(Color color) => color.toARGB32() & 0xFFFFFF;

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

  /// 网速格式化
  static String formatBytesPerSec(num bps) {
    final kb = bps / 1024.0;
    if (kb < 1024) return '${kb.toStringAsFixed(1)}KB/s';
    final mb = kb / 1024.0;
    return '${mb.toStringAsFixed(1)}MB/s';
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

  /// 将 GitHub 资源链接转换为 jsDelivr CDN 地址。
  ///
  /// 支持 `raw.githubusercontent.com` 与 `github.com/.../blob|raw/...` 格式；
  /// 已是 jsDelivr 链接或无法解析时原样返回。
  static String jsDelivrCdnUrl(String url) {
    var normalized = url;
    if (normalized.startsWith(CommonApi.jsDelivr)) {
      return normalized;
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null) return url;

    if (uri.host == 'raw.githubusercontent.com') {
      final segments = uri.pathSegments;
      if (segments.length < 3) return url;
      final user = segments[0];
      final repo = segments[1];
      final branch = segments[2];
      final filePath = segments.sublist(3).join('/');
      return '${CommonApi.jsDelivr}$user/$repo@$branch/$filePath';
    }

    if (uri.host == 'github.com' && uri.pathSegments.length >= 5) {
      final segments = uri.pathSegments;
      final type = segments[2];
      if (type == 'blob' || type == 'raw') {
        final user = segments[0];
        final repo = segments[1];
        final branch = segments[3];
        final filePath = segments.sublist(4).join('/');
        return '${CommonApi.jsDelivr}$user/$repo@$branch/$filePath';
      }
    }

    return url;
  }

  static double calculateSimilarity(String s1, String s2) {
    int maxLength = max(s1.length, s2.length);
    if (maxLength == 0) return 1.0;
    if (s1 == s2) return 1.0;
    return (1.0 - levenshteinDistance(s1, s2) / maxLength);
  }

  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[s2.length];
  }
}
