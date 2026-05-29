import 'dart:convert';

import 'package:crypto/crypto.dart';

/// AnimeFlow API 请求签名
class ApiSignature {
  ApiSignature._();

  static const String appId = String.fromEnvironment(
    'ANIME_FLOW_APP_ID',
    defaultValue: 'xxxxxx',
  );

  static const String secret = String.fromEnvironment(
    'ANIME_FLOW_SECRET',
    defaultValue: 'xxxxxxxxxxxxxxxxxx',
  );

  static Map<String, dynamic> headers(String path) {
    final signPath = _normalizePath(path);
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return {
      'X-Auth': '1',
      'X-AppId': appId,
      'X-Timestamp': timestamp,
      'X-Signature': generateSignature(signPath, timestamp),
    };
  }

  static String generateSignature(String path, int timestamp) {
    final signPath = _normalizePath(path);
    final data = appId + timestamp.toString() + signPath + secret;
    final digest = sha256.convert(utf8.encode(data));
    return base64Encode(digest.bytes);
  }

  static String _normalizePath(String path) {
    if (path.isEmpty) {
      return '/';
    }
    return path.startsWith('/') ? path : '/$path';
  }
}
