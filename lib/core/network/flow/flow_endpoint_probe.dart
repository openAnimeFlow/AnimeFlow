import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/core/logger/logger.dart';

import 'flow_connection_connector.dart';

/// 每次测量新建连接的耗时，均使用独立且不携带凭据的客户端。
class FlowEndpointProbe {
  FlowEndpointProbe({required this.endpoint, this.securityContext});

  static const _timeout = Duration(seconds: 3);
  static const _maxBodyBytes = 8192;

  final Uri endpoint;
  final SecurityContext? securityContext;
  final Set<HttpClient> _clients = {};
  final Set<FlowConnectionContext> _contexts = {};
  final Completer<void> _cancelled = Completer<void>();

  Future<Duration?> probe(String? address) async {
    if (_cancelled.isCompleted) return null;
    final uri =
        endpoint.replace(path: '/cdn-cgi/trace', query: null, fragment: null);
    // 显式代理沿用正常连接路径；此时直连 IP 的测量结果不能反映实际请求路径。
    const findProxy = HttpClient.findProxyFromEnvironment;
    if (findProxy(uri) != 'DIRECT') return null;
    final context = FlowConnectionContext(budget: _timeout);
    final connector = FlowConnectionConnector(
        endpoint: endpoint,
        addresses: address == null ? const [] : [address],
        allowDnsFallback: false,
        candidateTimeout: _timeout,
        securityContext: securityContext);
    final client = connector.createClient()
      ..findProxy = findProxy
      ..connectionTimeout = _timeout;
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
            response.contentLength > _maxBodyBytes) {
          LiggLogger().d('Flow IP 探测 ${address ?? 'DNS'} 不接受响应 '
              '(HTTP ${response.statusCode}, length ${response.contentLength})');
          return null;
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > _maxBodyBytes) return null;
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
      ]).timeout(_timeout);
    } catch (error) {
      if (!_cancelled.isCompleted) {
        LiggLogger()
            .d('Flow IP 探测 ${address ?? 'DNS'} 失败 (${error.runtimeType})');
      }
      return null;
    } finally {
      context.cancel();
      client.close(force: true);
      _clients.remove(client);
      _contexts.remove(context);
    }
  }

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
