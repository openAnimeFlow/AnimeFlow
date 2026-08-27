import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/features/download/application/download_http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late Uri baseUri;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUri = Uri.parse('http://${server.address.host}:${server.port}');
    _serveRequests(server);
  });

  tearDown(() async {
    await server.close(force: true);
  });

  group('DownloadHttpClient', () {
    test('gets plain text with request headers', () async {
      final client = DownloadHttpClient(dio: Dio());

      final text = await client.getPlain(
        baseUri.resolve('/plain').toString(),
        headers: {'x-test-header': 'anime-flow'},
      );

      expect(text, 'plain:anime-flow');
    });

    test('gets response stream', () async {
      final client = DownloadHttpClient(dio: Dio());

      final response = await client.getStream(
        baseUri.resolve('/stream').toString(),
        headers: const {},
      );
      final chunks = <int>[];
      await for (final chunk in response.data!.stream) {
        chunks.addAll(chunk);
      }

      expect(utf8.decode(chunks), 'stream-body');
    });

    test('downloads file to path', () async {
      final client = DownloadHttpClient(dio: Dio());
      final tempDir = Directory.systemTemp.createTempSync(
        'anime_flow_download_http_test_',
      );
      final savePath = '${tempDir.path}${Platform.pathSeparator}video.bin';

      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      await client.download(
        baseUri.resolve('/download').toString(),
        savePath,
        headers: const {},
      );

      expect(File(savePath).readAsStringSync(), 'download-body');
    });
  });
}

void _serveRequests(HttpServer server) {
  server.listen((request) async {
    switch (request.uri.path) {
      case '/plain':
        request.response.write(
          'plain:${request.headers.value('x-test-header') ?? ''}',
        );
      case '/stream':
        request.response.write('stream-body');
      case '/download':
        request.response.write('download-body');
      default:
        request.response.statusCode = HttpStatus.notFound;
    }
    await request.response.close();
  });
}
