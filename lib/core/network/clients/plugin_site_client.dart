import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/network/core/network_error_mapper.dart';
import 'package:dio/dio.dart';

/// 规则站点请求客户端。
///
/// 使用独立的 [DioFactory.pluginDio]，与访问官方接口的 `apiDio` 隔离：
/// 第三方规则站点不应拿到应用自身的默认请求头或鉴权信息。
/// 规则所需的头、Cookie、请求体全部由调用方显式提供。
class PluginSiteClient {
  PluginSiteClient._();

  static final PluginSiteClient instance = PluginSiteClient._();

  /// 发送一次请求并返回原始响应文本。
  ///
  /// 固定使用 [ResponseType.plain]，JSON 响应同样以字符串返回，
  /// 由解析层决定是否 `jsonDecode`，避免 Dio 自动解析带来的类型差异。
  Future<String> requestText(
    String url, {
    required String method,
    Map<String, dynamic> headers = const <String, dynamic>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? data,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await DioFactory.pluginDio.request<String>(
        url,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(
          method: method,
          headers: headers,
          responseType: ResponseType.plain,
        ),
      );
      return response.data ?? '';
    } on DioException catch (error) {
      throw await NetworkErrorMapper.mapException(error);
    }
  }
}
