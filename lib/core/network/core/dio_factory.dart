import 'package:anime_flow/core/network/clients/flow_token_refresh_client.dart';
import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_pool.dart';
import 'package:anime_flow/core/network/flow/flow_http_client_adapter.dart';
import 'package:anime_flow/core/network/interceptors/dio_logger_interceptor.dart';
import 'package:anime_flow/core/network/interceptors/flow_refresh_token_interceptor.dart';
import 'package:anime_flow/core/auth/repository/flow_token_storage.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'network_config.dart';

class DioFactory {
  DioFactory._();

  static Dio? _apiDio;
  static Dio? _githubDio;
  static Dio? _pluginDio;
  static Dio? _downloadDio;
  static Dio? _animeFlowDio;
  static Dio? _animeFlowRefreshDio;

  static Dio get apiDio => _apiDio ??= _create(
        NetworkConfig.fromSettings(),
        defaultHeaders: {
          'referer': '',
          'user-agent': Utils.getRandomUA(),
        },
      );

  static Dio get animeFlowDio {
    if (_animeFlowDio != null) return _animeFlowDio!;
    final dio = _createAnimeFlowTransport();
    final refreshClient = FlowTokenRefreshClient(animeFlowRefreshDio);
    dio.interceptors.add(
      FlowRefreshTokenInterceptor(dio, FlowTokenStorage.instance,
          refreshToken: refreshClient.refresh),
    );
    return _animeFlowDio = dio;
  }

  /// Dedicated refresh transport. It never installs the session interceptor.
  static Dio get animeFlowRefreshDio =>
      _animeFlowRefreshDio ??= _createAnimeFlowTransport();

  static Dio _createAnimeFlowTransport() {
    final dio = _create(
      NetworkConfig.fromSettings(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        allowBadCertificates: false,
      ),
      baseUrl: AnimeFlowApi.animeFlowApi,
      adapter: FlowHttpClientAdapter(pool: FlowEndpointPool.instance),
    );
    Future<String>? deviceUserAgent;
    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      if (!options.headers.containsKey('user-agent')) {
        options.headers['user-agent'] = await (deviceUserAgent ??=
            Utils.getCurrentUserAgent().catchError((Object error) {
          LiggLogger().w('生成或校验设备 User-Agent 失败，使用基础 AnimeFlow UA (${error.runtimeType})');
          return 'AnimeFlow/unknown';
        }));
      }
      handler.next(options);
    }));
    return dio;
  }

  static Dio get githubDio => _githubDio ??= _create(
        NetworkConfig.fromSettings(),
        defaultHeaders: {
          'accept': 'application/vnd.github+json',
          'user-agent': Utils.getRandomUA(),
        },
        interceptors: [_GithubMirrorInterceptor()],
      );

  static Dio get pluginDio => _pluginDio ??= _create(
        NetworkConfig.fromSettings(),
        defaultHeaders: {
          'user-agent': Utils.getRandomUA(),
          'accept-language': Utils.getRandomAcceptedLanguage(),
        },
      );

  static Dio get downloadDio => _downloadDio ??= _create(
        NetworkConfig.fromSettings(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
        defaultHeaders: {
          'user-agent': Utils.getRandomUA(),
        },
      );

  /// 清空工厂缓存
  static void reset() {
    _animeFlowDio?.close();
    _animeFlowRefreshDio?.close();
    _apiDio = null;
    _githubDio = null;
    _pluginDio = null;
    _downloadDio = null;
    _animeFlowDio = null;
    _animeFlowRefreshDio = null;
  }

  static Dio _create(
    NetworkConfig config, {
    String? baseUrl,
    HttpClientAdapter? adapter,
    Map<String, dynamic> defaultHeaders = const {},
    List<Interceptor> interceptors = const [],
  }) {
    // Keep the constructor tear-off form so the migration guard can flag
    // direct Dio construction outside this factory with a simple search.
    // ignore: unnecessary_constructor_name
    final dio = Dio.new(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        headers: defaultHeaders,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );
    dio.httpClientAdapter = adapter ?? config.createAdapter();
    dio.transformer = BackgroundTransformer();
    dio.interceptors.addAll(interceptors);
    if (config.enableLog) {
      dio.interceptors.add(DioLoggerInterceptor());
    }
    return dio;
  }
}

class _GithubMirrorInterceptor extends Interceptor {
  static const _mirrorableHosts = {
    'api.github.com',
    'github.com',
    'raw.githubusercontent.com',
    'objects.githubusercontent.com',
    'github-releases.githubusercontent.com',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri;
    if (!_mirrorableHosts.contains(uri.host)) {
      handler.next(options);
      return;
    }

    final mirrored = '${CommonApi.gitMirror}${uri.toString()}';
    LiggLogger().d('GitHub mirror: $mirrored');
    options.path = mirrored;
    handler.next(options);
  }
}
