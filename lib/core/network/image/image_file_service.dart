import 'dart:io';

import 'package:anime_flow/core/network/image/image_file_response.dart';
import 'package:anime_flow/core/network/image/ech_image_service.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/ech_image_route.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ImageFileService extends FileService {
  ImageFileService({
    EchImageService? echService,
    http.Client Function()? clientFactory,
  })  : _echEnabled = AppSettings.echImageLoading,
        _echRoutes = {
          for (final route in AppSettings.echImageRoutes) route.host: route,
        },
        _echService =
            echService ?? EchImageService(routes: AppSettings.echImageRoutes),
        _clientFactory = clientFactory ?? _createHttpClient;

  final bool _echEnabled;
  final Map<String, EchImageRoute> _echRoutes;
  final EchImageService _echService;
  final http.Client Function() _clientFactory;
  final _clients = <http.Client>{};
  bool _closed = false;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (_closed) throw StateError('Image file service is closed');
    final uri = Uri.parse(url);
    final route = _echRoutes[uri.host];
    if (_echEnabled &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        route != null) {
      // Keep the requested domain, path and query; ECH requires HTTPS.
      final echUri = uri.scheme == 'http'
          ? uri.replace(
              scheme: 'https',
              port: uri.hasPort && uri.port != 80 ? uri.port : 443,
            )
          : uri;
      return _echService.get(
        echUri,
        host: route.host,
        fixedIps: route.fixedIps,
        headers: headers,
      );
    }

    final client = _clientFactory();
    _clients.add(client);
    try {
      final request = http.Request('GET', uri);
      if (headers != null) request.headers.addAll(headers);
      final response = await client.send(request);
      return await createImageFileResponse(
        response,
        contentLength: response.contentLength,
        onComplete: () => _release(client),
      );
    } catch (_) {
      _release(client);
      rethrow;
    }
  }

  void close() {
    _closed = true;
    _echService.close();
    for (final client in _clients) {
      client.close();
    }
    _clients.clear();
  }

  void _release(http.Client client) {
    if (_clients.remove(client)) client.close();
  }

  static http.Client _createHttpClient() => IOClient(HttpClient());
}
