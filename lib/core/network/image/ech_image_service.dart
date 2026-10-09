import 'dart:io' show HttpClientResponseCompressionState;

import 'package:anime_flow/core/network/image/image_file_response.dart';
import 'package:anime_flow/core/settings/ech_image_route.dart';
import 'package:ech_http/ech_http.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Downloads images with the ECH route configured in general settings.
class EchImageService {
  EchImageService({Iterable<EchImageRoute> routes = const []})
      : _routes = {for (final route in routes) route.host: route.fixedIps};

  final Map<String, List<String>> _routes;
  static final _dohEndpoint = Uri.https('dns.alidns.com', '/resolve');
  final _sessionsByHost = <String, _EchSession>{};
  final _sessions = <_EchSession>{};
  bool _closed = false;

  _EchSession _sessionFor(String host, List<String> fixedIps) {
    if (_closed) throw StateError('ECH image service is closed');
    final current = _sessionsByHost[host];
    if (current != null &&
        current.host == host &&
        listEquals(current.fixedIps, fixedIps)) {
      return current;
    }
    if (current != null) {
      current.retired = true;
      _sessionsByHost.remove(host);
      if (current.active == 0 && _sessions.remove(current)) current.close();
    }

    final hosts = {..._routes.keys, host};
    final bootstrap = EchClient();
    try {
      final images = EchClient(
        resolver: DohEchResolver(
          client: bootstrap,
          endpoint: _dohEndpoint,
          // Redirects to another configured domain must also use ECH.
          hosts: hosts,
          // Bangumi uses Cloudflare's shared ECH config, as in Kazumi.
          configDomains: {
            if (hosts.contains('lain.bgm.tv'))
              'lain.bgm.tv': 'crypto.cloudflare.com',
          },
          addressOverrides: {
            for (final entry in _routes.entries)
              if (entry.key != host && entry.value.isNotEmpty)
                entry.key: entry.value,
            if (fixedIps.isNotEmpty) host: fixedIps,
          },
        ),
      );
      final session =
          _EchSession(host, List.unmodifiable(fixedIps), bootstrap, images);
      _sessions.add(session);
      return _sessionsByHost[host] = session;
    } catch (_) {
      bootstrap.close();
      rethrow;
    }
  }

  Future<FileServiceResponse> get(
    Uri uri, {
    required String host,
    List<String> fixedIps = const [],
    Map<String, String>? headers,
  }) async {
    final session = _sessionFor(host, fixedIps);
    session.active++;
    final http.StreamedResponse response;
    try {
      final request = http.Request('GET', uri);
      if (headers != null) request.headers.addAll(headers);
      response = await session.images.send(request);
    } catch (_) {
      _release(session);
      rethrow;
    }
    return createImageFileResponse(
      response,
      // ech_http keeps wire lengths even when its stream is gzip-decoded.
      contentLength: response is EchResponse &&
              response.compressionState ==
                  HttpClientResponseCompressionState.decompressed
          ? null
          : response.contentLength,
      onComplete: () => _release(session),
    );
  }

  void _release(_EchSession session) {
    session.active--;
    if (session.retired && session.active == 0 && _sessions.remove(session)) {
      session.close();
    }
  }

  void close() {
    _closed = true;
    _sessionsByHost.clear();
    for (final session in _sessions) {
      session.close();
    }
    _sessions.clear();
  }
}

class _EchSession {
  _EchSession(this.host, this.fixedIps, this.bootstrap, this.images);

  final String host;
  final List<String> fixedIps;
  final http.Client bootstrap;
  final http.Client images;
  int active = 0;
  bool retired = false;

  void close() {
    images.close();
    bootstrap.close();
  }
}
