import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/network/core/network_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:anime_flow/shared/models/download_info.dart';

/// Downloads release assets without changing the version metadata API.
class AppUpdateClient {
  AppUpdateClient._();

  static final instance = AppUpdateClient._();

  static String mirrorUrl(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme == 'https' &&
        const {
          'github.com',
          'objects.githubusercontent.com',
          'release-assets.githubusercontent.com',
          'github-releases.githubusercontent.com',
        }.contains(uri.host)) {
      return 'https://${CommonApi.ghProxy}/$url';
    }
    return url;
  }

  Future<void> download(
    String url,
    String savePath, {
    UpdateDownloadRoute route = UpdateDownloadRoute.github,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    final file = File(savePath);
    RandomAccessFile? output;
    StreamIterator<Uint8List>? chunks;
    var created = false;
    var complete = false;
    try {
      final response = await DioFactory.appUpdateDio.get<ResponseBody>(
        route == UpdateDownloadRoute.ghProxy ? mirrorUrl(url) : url,
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );
      final body = response.data!;
      chunks = StreamIterator(body.stream);
      await file.parent.create(recursive: true);
      output = await file.open(mode: FileMode.write);
      created = true;
      var received = 0;
      while (await chunks.moveNext()) {
        if (cancelToken?.isCancelled == true) throw cancelToken!.cancelError!;
        final chunk = chunks.current;
        await output.writeFrom(chunk);
        received += chunk.length;
        onReceiveProgress?.call(received, body.contentLength);
      }
      if (cancelToken?.isCancelled == true) throw cancelToken!.cancelError!;
      if (body.contentLength >= 0 && received != body.contentLength) {
        throw FileSystemException('更新包下载不完整，请重试', savePath);
      }
      await output.close();
      output = null;
      complete = true;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw await NetworkErrorMapper.mapException(error);
    } finally {
      // Finish outstanding writes and cleanup before reporting cancellation.
      await chunks?.cancel();
      await output?.close();
      if (created && !complete && await file.exists()) await file.delete();
    }
  }
}
