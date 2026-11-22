import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/network/core/network_error_mapper.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/rules_mirror.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:dio/dio.dart';

class RulesRepoClient {
  RulesRepoClient._();

  static final instance = RulesRepoClient._();

  static String resolveUrl(String url, RulesMirror mirror) => switch (mirror) {
        RulesMirror.ghProxy => 'https://${CommonApi.ghProxy}/$url',
        RulesMirror.jsDelivr => _jsDelivrUrl(url),
        RulesMirror.direct => url,
      };

  static String _jsDelivrUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    if (uri.host != 'raw.githubusercontent.com' || segments.length < 4) {
      return Utils.jsDelivrCdnUrl(url);
    }
    return Uri(
      scheme: 'https',
      host: 'cdn.jsdelivr.net',
      pathSegments: [
        'gh',
        segments[0],
        '${segments[1]}@${segments[2]}',
        ...segments.skip(3)
      ],
      query: uri.hasQuery ? uri.query : null,
    ).toString();
  }

  Future<String> getText(
    String url, {
    RulesMirror? mirror,
    CancelToken? cancelToken,
  }) async =>
      await _get<String>(url, mirror ?? AppSettings.rulesMirror,
          ResponseType.plain, cancelToken) ??
      '';

  Future<List<int>> getBytes(
    String url, {
    required RulesMirror mirror,
    CancelToken? cancelToken,
  }) async =>
      await _get<List<int>>(url, mirror, ResponseType.bytes, cancelToken) ??
      const [];

  Future<T?> _get<T>(String url, RulesMirror mirror, ResponseType responseType,
      CancelToken? cancelToken) async {
    try {
      final response = await DioFactory.rulesRepoDio.get<T>(
        resolveUrl(url, mirror),
        options: Options(responseType: responseType),
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw await NetworkErrorMapper.mapException(error);
    }
  }
}
