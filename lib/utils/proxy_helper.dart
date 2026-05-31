import 'dart:io';
import 'package:system_network_proxy/system_network_proxy.dart';
import 'package:flutter/foundation.dart';

class ProxyHelper {
  static String? _systemProxy;

  static Future<void> init() async {
    if (kIsWeb) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      SystemNetworkProxy.init();
      try {
        final proxyEnable = await SystemNetworkProxy.getProxyEnable();
        if (proxyEnable) {
          final proxyServer = await SystemNetworkProxy.getProxyServer();
          _systemProxy = _parseSystemProxy(proxyServer);
          
          // Apply globally for all default HttpClient creations
          if (_systemProxy != null && _systemProxy!.isNotEmpty) {
            HttpOverrides.global = _ProxyHttpOverrides(_systemProxy!);
          }
        }
      } catch (e) {
        debugPrint('Failed to get system proxy: $e');
      }
    }
  }

  static String? _parseSystemProxy(String proxyServer) {
    if (proxyServer.isEmpty) return null;
    // On Windows, proxyServer might look like "http=127.0.0.1:7890;https=127.0.0.1:7890" or "127.0.0.1:7890"
    if (proxyServer.contains(';')) {
      final parts = proxyServer.split(';');
      for (var part in parts) {
        if (part.startsWith('http=') || part.startsWith('https=')) {
          return part.split('=')[1];
        }
      }
    }
    return proxyServer;
  }

  static String resolveProxy(Uri uri) {
    if (_systemProxy != null && _systemProxy!.isNotEmpty) {
      return 'PROXY $_systemProxy; DIRECT';
    }
    return HttpClient.findProxyFromEnvironment(uri);
  }
}

class _ProxyHttpOverrides extends HttpOverrides {
  final String proxy;
  _ProxyHttpOverrides(this.proxy);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => 'PROXY $proxy; DIRECT';
    return client;
  }
}
