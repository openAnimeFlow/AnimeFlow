import 'dart:io';
import 'package:dio/io.dart';
import 'package:anime_flow/utils/proxy_helper.dart';

class NetworkConfig {
  const NetworkConfig({
    this.connectTimeout = const Duration(seconds: 12),
    this.receiveTimeout = const Duration(seconds: 12),
    this.sendTimeout,
    this.allowBadCertificates = false,
    this.enableLog = true,
  });

  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration? sendTimeout;
  final bool allowBadCertificates;
  final bool enableLog;


  IOHttpClientAdapter createAdapter() {
    return IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.findProxy = ProxyHelper.resolveProxy;
        if (allowBadCertificates) {
          client.badCertificateCallback = (cert, host, port) => true;
        }
        return client;
      },
    );
  }

  NetworkConfig copyWith({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    String? proxyHost,
    int? proxyPort,
    bool? clearProxy,
    bool? allowBadCertificates,
    bool? enableLog,
  }) {
    return NetworkConfig(
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      allowBadCertificates: allowBadCertificates ?? this.allowBadCertificates,
      enableLog: enableLog ?? this.enableLog,
    );
  }

  static NetworkConfig fromSettings({
    Duration connectTimeout = const Duration(seconds: 12),
    Duration receiveTimeout = const Duration(seconds: 12),
    Duration? sendTimeout,
  }) {

    return NetworkConfig(
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      allowBadCertificates: true,
    );
  }
}
