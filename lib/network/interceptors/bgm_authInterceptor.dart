import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/repository/BangumiToken.dart';
import 'package:dio/dio.dart';

class BgmAuthInterceptor extends Interceptor {
  final BangumiToken _tokenRepository;

  BgmAuthInterceptor(this._tokenRepository);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenRepository.getToken();
    if (token != null) {
      options.headers[Constants.authorization] = '${token.tokenType} ${token.accessToken}';
    }
    return handler.next(options);
  }
}
