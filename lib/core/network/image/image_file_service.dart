import 'dart:io';

import 'package:anime_flow/core/network/image/image_file_response.dart';
import 'package:anime_flow/core/network/image/ech_image_service.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ImageFileService extends FileService {
  ImageFileService()
      : _echEnabled = AppSettings.echImageLoading,
        _echHost = AppSettings.echImageHost,
        _echFixedIps = AppSettings.echImageFixedIps,
        _echService = EchImageService();

  final bool _echEnabled;
  final String _echHost;
  final List<String> _echFixedIps;
  final EchImageService _echService;
  bool _closed = false;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (_closed) throw StateError('Image file service is closed');
    final uri = Uri.parse(url);
    if (_echEnabled &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.queryParameters.containsKey('url') &&
        (uri.host == AppSettings.defaultEchImageHost || uri.host == _echHost)) {
      final echUri = uri.replace(scheme: 'https', host: _echHost, port: 443);
      return _echService.get(
        echUri,
        host: _echHost,
        fixedIps: _echFixedIps,
        headers: headers,
      );
    }

    final client = IOClient(HttpClient());
    try {
      final request = http.Request('GET', uri);
      if (headers != null) request.headers.addAll(headers);
      final response = await client.send(request);
      return await createImageFileResponse(response, onComplete: client.close);
    } catch (_) {
      client.close();
      rethrow;
    }
  }

  void close() {
    _closed = true;
    _echService.close();
  }
}
