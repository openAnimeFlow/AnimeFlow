import 'dart:async';
import 'dart:io' show HttpClientResponseCompressionState;
import 'dart:typed_data';

import 'package:anime_flow/core/network/api_path.dart';
import 'package:dio/dio.dart';
import 'package:ech_http/ech_http.dart';
import 'package:http/http.dart' as http;

/// Streams installers through ECH without buffering the package in memory.
class UpdateEchAdapter implements HttpClientAdapter {
  UpdateEchAdapter({required HttpClientAdapter fallback, this.clientFactory})
      : _fallback = fallback;

  final HttpClientAdapter _fallback;
  final http.Client Function()? clientFactory;
  final _active = <void Function()>{};
  bool _closed = false;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (_closed) throw StateError('Update transport is closed');
    if (options.uri.host != CommonApi.ghProxy) {
      return _fallback.fetch(options, requestStream, cancelFuture);
    }
    final connectTimeout =
        options.connectTimeout ?? const Duration(seconds: 15);
    final receiveTimeout =
        options.receiveTimeout ?? const Duration(seconds: 30);
    http.Client? bootstrap;
    http.Client? client;
    bool cancelled = false;
    bool released = false;
    void release() {
      if (released) return;
      released = true;
      _active.remove(release);
      client?.close();
      bootstrap?.close();
    }

    DioException mapError(Object error, StackTrace stack) {
      if (cancelled) {
        return DioException.requestCancelled(
            requestOptions: options,
            reason: 'Update download cancelled',
            stackTrace: stack);
      }
      if (error is DioException) return error;
      if (error is TimeoutException ||
          error is EchException && error.nativeCode == 28) {
        return DioException.receiveTimeout(
            requestOptions: options, timeout: receiveTimeout, error: error);
      }
      return DioException.connectionError(
          requestOptions: options,
          reason: error.toString(),
          error: error,
          stackTrace: stack);
    }

    try {
      if (clientFactory != null) {
        client = clientFactory!();
      } else {
        bootstrap = EchClient();
        client = EchClient(
          connectTimeout: connectTimeout,
          // Native timeout covers the whole transfer; idle reads are bounded
          // separately below. Installers may exceed the default 32 MiB limit.
          timeout: const Duration(hours: 2),
          maxResponseBytes: 4 * 1024 * 1024 * 1024,
          resolver: DohEchResolver(
            client: bootstrap,
            endpoint: Uri.https('dns.alidns.com', '/resolve'),
            hosts: {CommonApi.ghProxy},
            configDomains: {CommonApi.ghProxy: 'crypto.cloudflare.com'},
            addressOverrides: {
              CommonApi.ghProxy: [
                '172.67.134.140',
                '104.21.6.61',
                '172.67.73.67'
              ],
            },
          ),
        );
      }
      _active.add(release);
      final request = http.Request(options.method, options.uri)
        ..followRedirects = options.followRedirects
        ..maxRedirects = options.maxRedirects;
      for (final entry in options.headers.entries) {
        if (entry.value != null) request.headers[entry.key] = '${entry.value}';
      }
      // Keep file byte counts/progress consistent with Content-Length.
      request.headers.putIfAbsent('accept-encoding', () => 'identity');
      final aborted = Completer<http.StreamedResponse>();
      cancelFuture?.then((_) {
        if (released) return;
        cancelled = true;
        aborted.completeError(
            mapError(StateError('cancelled'), StackTrace.current));
        release();
      });
      final response = await Future.any([
        client.send(request),
        aborted.future,
      ]).timeout(connectTimeout + receiveTimeout);

      Stream<Uint8List> body() async* {
        try {
          await for (final chunk in response.stream.timeout(receiveTimeout)) {
            if (released) return;
            yield chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
          }
        } catch (error, stack) {
          // Dio reports cancellation/timeout and cancels its subscription when
          // closing the response. Do not emit a second error from client.close.
          if (released) return;
          throw mapError(error, stack);
        } finally {
          release();
        }
      }

      final decompressed = response is EchResponse &&
          response.compressionState ==
              HttpClientResponseCompressionState.decompressed;
      return ResponseBody(
        body(),
        response.statusCode,
        headers: {
          for (final entry in response.headers.entries)
            if (!decompressed ||
                !{'content-length', 'content-encoding'}
                    .contains(entry.key.toLowerCase()))
              entry.key: [entry.value],
        },
        statusMessage: response.reasonPhrase,
        isRedirect: response.isRedirect,
        onClose: release,
      );
    } catch (error, stack) {
      release();
      throw mapError(error, stack);
    }
  }

  @override
  void close({bool force = false}) {
    _closed = true;
    _fallback.close(force: force);
    if (force) {
      for (final release in _active.toList()) {
        release();
      }
    }
  }
}
