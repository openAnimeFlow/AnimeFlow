import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'dio_logger_interceptor.dart';
import 'network_config.dart';

class DioFactory {
  DioFactory._();

  static Dio? _apiDio;
  static Dio? _githubDio;
  static Dio? _pluginDio;
  static Dio? _downloadDio;
  static Dio? _bangumiDio;
  static Dio? _animeFlowDio;

  static Dio get apiDio => _apiDio ??= _create(
    NetworkConfig.fromSettings(),
    defaultHeaders: {
      'referer': '',
      'user-agent': Utils.getRandomUA(),
    },
  );

  static Dio get animeFlowDio => _animeFlowDio ??= _create(
    NetworkConfig.fromSettings(),
    defaultHeaders: {
      'referer': '',
      'user-agent': Utils.getRandomUA(),
    },
  );

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

  static Dio get bangumiDio => _bangumiDio ??= _create(
        NetworkConfig.fromSettings(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

  static Dio createForConfig(NetworkConfig config) {
    return _create(config);
  }

  static void reset() {
    _apiDio = null;
    _githubDio = null;
    _pluginDio = null;
    _downloadDio = null;
    _bangumiDio = null;
    _animeFlowDio = null;
  }

  static Dio _create(
      NetworkConfig config, {
        Map<String, dynamic> defaultHeaders = const {},
        List<Interceptor> interceptors = const [],
      }) {
    // Keep the constructor tear-off form so the migration guard can flag
    // direct Dio construction outside this factory with a simple search.
    // ignore: unnecessary_constructor_name
    final dio = Dio.new(
      BaseOptions(
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        headers: defaultHeaders,
        validateStatus: (status) =>
        status != null && status >= 200 && status < 300,
      ),
    );
    dio.httpClientAdapter = config.createAdapter();
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
    Logger().d('GitHub mirror: $mirrored');
    options.path = mirrored;
    handler.next(options);
  }
}
