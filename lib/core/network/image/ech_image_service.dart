import 'package:anime_flow/core/network/image/image_file_response.dart';
import 'package:ech_http/ech_http.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Downloads images with the ECH route configured in general settings.
class EchImageService {
  static final _dohEndpoint = Uri.https('dns.alidns.com', '/resolve');

  _EchSession? _current;
  final _sessions = <_EchSession>{};
  bool _closed = false;

  _EchSession _sessionFor(String host, List<String> fixedIps) {
    if (_closed) throw StateError('ECH image service is closed');
    final current = _current;
    if (current != null &&
        current.host == host &&
        listEquals(current.fixedIps, fixedIps)) {
      return current;
    }
    if (current != null) {
      current.retired = true;
      _current = null;
      if (current.active == 0 && _sessions.remove(current)) current.close();
    }

    final bootstrap = EchClient();
    try {
      final images = EchClient(
        resolver: DohEchResolver(
          client: bootstrap,
          endpoint: _dohEndpoint,
          hosts: {host},
          addressOverrides: {
            if (fixedIps.isNotEmpty) host: fixedIps,
          },
        ),
      );
      final session =
          _EchSession(host, List.unmodifiable(fixedIps), bootstrap, images);
      _sessions.add(session);
      return _current = session;
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
      // ech_http does not decode compressed HTTP response bodies.
      request.headers['accept-encoding'] = 'identity';
      response = await session.images.send(request);
    } catch (_) {
      _release(session);
      rethrow;
    }
    return createImageFileResponse(response,
        onComplete: () => _release(session));
  }

  void _release(_EchSession session) {
    session.active--;
    if (session.retired && session.active == 0 && _sessions.remove(session)) {
      session.close();
    }
  }

  void close() {
    _closed = true;
    _current = null;
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
