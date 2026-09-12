import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../domain/hls_snapshot.dart';

class MediaHttpResponse {
  const MediaHttpResponse(this.uri, this.bytes, this.headers);
  final Uri uri;
  final Uint8List bytes;
  final Map<String, String> headers;
}

/// A dedicated media client avoids app API interceptors, cookie jars and logs.
/// Credentials are scoped to the resolved media origin and stripped on every
/// cross-origin hop, including custom token headers. No automatic redirects.
class MediaHttpFetcher {
  MediaHttpFetcher() : _client = HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 10);
    _client.autoUncompress = true;
  }
  final HttpClient _client;
  void close() => _client.close(force: true);

  Future<MediaHttpResponse> get(
    Uri uri, {
    required Uri credentialOrigin,
    required Map<String, String> headers,
    required int limit,
  }) async {
    var target = uri;
    var allowCredentials = target.origin == credentialOrigin.origin;
    try {
      for (var redirects = 0; redirects <= 5; redirects++) {
        HlsSnapshot.checkHttpUri(target);
        final request = await _client.getUrl(target);
        request.followRedirects = false;
        for (final entry in headers.entries) {
          final key = entry.key.toLowerCase();
          if ({
            'host',
            'connection',
            'content-length',
            'range',
            'accept-encoding',
            'transfer-encoding'
          }.contains(key)) {
            continue;
          }
          if (allowCredentials || {'user-agent', 'accept'}.contains(key)) {
            request.headers.set(key, entry.value);
          }
        }
        request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
        final response = await request
            .close()
            .timeout(const Duration(seconds: 15), onTimeout: () {
          request.abort();
          throw TimeoutException('Media headers timeout');
        });
        if ({301, 302, 303, 307, 308}.contains(response.statusCode)) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          await response.listen((_) {}).cancel();
          if (location == null) HlsSnapshot.unsupported();
          final next = target.resolve(location);
          // Never restore credentials after a redirect away from their origin.
          allowCredentials = allowCredentials && next.origin == target.origin;
          if (target.scheme == 'https' && next.scheme != 'https') {
            HlsSnapshot.unsupported();
          }
          target = next;
          continue;
        }
        if (response.statusCode != HttpStatus.ok ||
            response.contentLength > limit) {
          await response.listen((_) {}).cancel();
          throw const MediaCacheException(
              MediaCacheIssue.unavailable, '媒体请求失败或资源超过缓存限制');
        }
        final bytes = BytesBuilder(copy: false);
        final timeout = Timer(const Duration(seconds: 45), request.abort);
        try {
          await for (final chunk
              in response.timeout(const Duration(seconds: 15))) {
            if (bytes.length + chunk.length > limit) {
              request.abort();
              throw const MediaCacheException(
                  MediaCacheIssue.capacity, '媒体分片超过缓存限制');
            }
            bytes.add(chunk);
          }
        } finally {
          timeout.cancel();
        }
        if (bytes.isEmpty ||
            (response.contentLength >= 0 &&
                response.contentLength != bytes.length)) {
          throw const MediaCacheException(
              MediaCacheIssue.unavailable, '媒体响应不完整');
        }
        final responseHeaders = <String, String>{};
        response.headers.forEach((name, values) =>
            responseHeaders[name.toLowerCase()] = values.join(','));
        return MediaHttpResponse(target, bytes.takeBytes(), responseHeaders);
      }
      throw const MediaCacheException(MediaCacheIssue.unavailable, '媒体重定向次数过多');
    } on MediaCacheException {
      rethrow;
    } catch (_) {
      throw const MediaCacheException(
          MediaCacheIssue.unavailable, '媒体请求失败，请重新加载或关闭共享缓存');
    }
  }
}
