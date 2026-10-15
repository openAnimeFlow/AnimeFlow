import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/core/logger/logger.dart';

import 'flow_connection_connector.dart';

abstract interface class FlowProbeSession {
  Future<Duration?> probe(String? address);
  void cancel();
}

/// 每次测量新建连接的耗时，均使用独立且不携带凭据的客户端。
class FlowEndpointProbe implements FlowProbeSession {
  FlowEndpointProbe(
      {required this.endpoint,
      this.timeout = const Duration(seconds: 3),
      this.maxBodyBytes = 8192,
      this.securityContext,
      String Function(Uri)? findProxy,
      void Function(String)? onDiagnostic})
      : _findProxy = findProxy ?? HttpClient.findProxyFromEnvironment,
        _onDiagnostic = onDiagnostic ?? ((message) => LiggLogger().d(message));

  final Uri endpoint;
  final Duration timeout;
  final int maxBodyBytes;
  final SecurityContext? securityContext;
  final String Function(Uri) _findProxy;
  final void Function(String) _onDiagnostic;
  final Set<HttpClient> _clients = {};
  final Set<FlowConnectionContext> _contexts = {};
  final Completer<void> _cancelled = Completer<void>();

  @override
  Future<Duration?> probe(String? address) async {
    if (_cancelled.isCompleted) return null;
    final uri =
        endpoint.replace(path: '/cdn-cgi/trace', query: null, fragment: null);
    // 显式代理沿用正常连接路径；此时直连 IP 的测量结果不能反映实际请求路径。
    if (_findProxy(uri) != 'DIRECT') return null;
    final context = FlowConnectionContext(budget: timeout);
    final connector = FlowConnectionConnector(
        endpoint: endpoint,
        addresses: address == null ? const [] : [address],
        allowDnsFallback: false,
        candidateTimeout: timeout,
        securityContext: securityContext);
    final client = connector.createClient()
      ..findProxy = _findProxy
      ..connectionTimeout = timeout;
    _clients.add(client);
    _contexts.add(context);
    final watch = Stopwatch()..start();
    try {
      final operation = runZoned(() async {
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.acceptHeader, 'text/plain');
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok ||
            response.contentLength > maxBodyBytes) {
          _onDiagnostic('Flow IP 探测 ${address ?? 'DNS'} 不接受响应 '
              '(HTTP ${response.statusCode}, length ${response.contentLength})');
          return null;
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > maxBodyBytes) return null;
          bytes.addAll(chunk);
        }
        final fields = <String, String>{};
        for (final line in const LineSplitter().convert(utf8.decode(bytes))) {
          final separator = line.indexOf('=');
          if (separator > 0) {
            fields[line.substring(0, separator)] =
                line.substring(separator + 1);
          }
        }
        return fields['h'] == endpoint.host &&
                const {'TLSv1.2', 'TLSv1.3'}.contains(fields['tls'])
            ? watch.elapsed
            : null;
      }, zoneValues: {FlowConnectionContext.zoneKey: context});
      return await Future.any<Duration?>([
        operation,
        _cancelled.future.then<Duration?>((_) => null),
      ]).timeout(timeout);
    } catch (error) {
      if (!_cancelled.isCompleted) {
        _onDiagnostic(
            'Flow IP 探测 ${address ?? 'DNS'} 失败 (${error.runtimeType})');
      }
      return null;
    } finally {
      context.cancel();
      client.close(force: true);
      _clients.remove(client);
      _contexts.remove(context);
    }
  }

  @override
  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
    for (final context in _contexts.toList()) {
      context.cancel();
    }
    for (final client in _clients.toList()) {
      client.close(force: true);
    }
  }
}
