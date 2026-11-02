import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/network/core/network_error_mapper.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/rules_mirror.dart';
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
      return url;
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

  Future<String> getText(String url, {CancelToken? cancelToken}) async {
    final mirror = AppSettings.rulesMirror;
    try {
      final response = await DioFactory.rulesRepoDio.get<String>(
        resolveUrl(url, mirror),
        options: Options(responseType: ResponseType.plain),
        cancelToken: cancelToken,
      );
      return response.data ?? '';
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw await NetworkErrorMapper.mapException(error);
    }
  }
}
