import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ech_http/ech_http.dart';
import 'package:http/http.dart' as http;

/// ECH transport for rule mirrors; GitHub keeps the normal adapter.
class RulesEchAdapter implements HttpClientAdapter {
  RulesEchAdapter({required HttpClientAdapter fallback, this.clientFactory})
      : _fallback = fallback;

  final HttpClientAdapter _fallback;
  final http.Client Function()? clientFactory;
  final _clients = <http.Client>{};
  bool _closed = false;

  // Pin each mirror to its Cloudflare edges. jsDelivr's normal DNS can also
  // select Fastly, which cannot use the shared Cloudflare ECH configuration.
  static const _echAddresses = {
    'gh-proxy.org': ['172.67.134.140', '104.21.6.61', '172.67.73.67'],
    'cdn.jsdelivr.net': ['104.16.179.112', '104.16.180.112'],
  };

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (_closed) throw StateError('Rules transport is closed');
    if (!_echAddresses.containsKey(options.uri.host)) {
      return _fallback.fetch(options, requestStream, cancelFuture);
    }
    final timeout = (options.connectTimeout ?? const Duration(seconds: 12)) +
        (options.receiveTimeout ?? const Duration(seconds: 12));
    http.Client? bootstrap;
    http.Client? client;
    try {
      if (clientFactory != null) {
        client = clientFactory!();
      } else {
        bootstrap = EchClient();
        _clients.add(bootstrap);
        client = EchClient(
          connectTimeout: options.connectTimeout ?? const Duration(seconds: 12),
          timeout: timeout,
          resolver: DohEchResolver(
            client: bootstrap,
            endpoint: Uri.https('dns.alidns.com', '/resolve'),
            hosts: _echAddresses.keys.toSet(),
            configDomains: {
              for (final host in _echAddresses.keys)
                host: 'crypto.cloudflare.com',
            },
            addressOverrides: _echAddresses,
          ),
        );
      }
      _clients.add(client);
      final request = http.Request(options.method, options.uri)
        ..followRedirects = options.followRedirects
        ..maxRedirects = options.maxRedirects;
      for (final entry in options.headers.entries) {
        if (entry.value != null) request.headers[entry.key] = '${entry.value}';
      }
      // Rule files are bounded JSON documents. Consume the body before closing
      // the native client, and include DNS discovery/body reads in the timeout.
      final response = await Future.any([
        client.send(request).then(http.Response.fromStream),
        if (cancelFuture != null)
          cancelFuture.then<http.Response>((_) =>
              throw DioException.requestCancelled(
                  requestOptions: options, reason: 'Rule request cancelled')),
      ]).timeout(timeout);
      return ResponseBody.fromBytes(response.bodyBytes, response.statusCode,
          headers: {
            for (final entry in response.headers.entries)
              if (!{'content-length', 'content-encoding', 'transfer-encoding'}
                  .contains(entry.key.toLowerCase()))
                entry.key: [entry.value],
            'content-length': ['${response.bodyBytes.length}'],
          },
          statusMessage: response.reasonPhrase);
    } catch (error, stack) {
      if (error is DioException) rethrow;
      if (error is TimeoutException ||
          error is EchException && error.nativeCode == 28) {
        throw DioException.receiveTimeout(
            timeout: timeout, requestOptions: options, error: error);
      }
      throw DioException.connectionError(
          requestOptions: options,
          reason: error.toString(),
          error: error,
          stackTrace: stack);
    } finally {
      if (client != null && _clients.remove(client)) client.close();
      if (bootstrap != null && _clients.remove(bootstrap)) bootstrap.close();
    }
  }

  @override
  void close({bool force = false}) {
    _closed = true;
    _fallback.close(force: force);
    if (force) {
      for (final client in _clients) {
        client.close();
      }
      _clients.clear();
    }
  }
}
