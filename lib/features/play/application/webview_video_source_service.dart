import 'dart:async';

import 'package:anime_flow/core/webview/video/video_webview_controller.dart';
import 'package:anime_flow/features/play/application/video_source_service.dart';

/// WebView 视频源提供者
///
/// 使用 WebView 解析视频页面，提取视频源 URL。
/// WebView 实例在 Provider 生命周期内复用，解析任务串行执行，
/// 仅在 [dispose] 时才真正销毁 WebView。
class WebViewVideoSourceService implements IVideoSourceProvider {
  /// WebView2 环境是进程级资源，播放页之间必须复用同一个服务实例。
  static final shared = WebViewVideoSourceService();

  VideoWebviewController? _webview;
  StreamSubscription? _logSubscription;
  Future<void>? _initialization;

  Future<void>? _resolveTail = Future<void>.value();
  _ResolveRequest? _activeRequest;

  final StreamController<String> _logController =
      StreamController<String>.broadcast();
  Stream<String> get onLog => _logController.stream;

  /// The platform controller is exposed so desktop platforms can mount their
  /// native WebView in the widget tree when required by the plugin.
  Object? get webviewController => _webview?.webviewController;

  Future<void> ensureInitialized() async {
    if (_webview != null) {
      final initialization = _initialization;
      if (initialization != null) {
        await initialization;
      }
      return;
    }

    final initialization = _initialization;
    if (initialization != null) {
      await initialization;
      return;
    }

    final webview = VideoWebviewControllerFactory.getController();
    _webview = webview;
    final initFuture = webview.init();
    _initialization = initFuture;
    try {
      await initFuture;
    } catch (_) {
      if (identical(_webview, webview)) {
        _webview = null;
      }
      rethrow;
    } finally {
      if (identical(_initialization, initFuture)) {
        _initialization = null;
      }
    }
    _logSubscription = _webview!.onLog.listen((log) {
      if (!_logController.isClosed) {
        _logController.add(log);
      }
    });
  }

  @override
  Future<VideoSource> resolve(
    String episodeUrl, {
    required bool useLegacyParser,
    int offset = 0,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final resolveTail = _resolveTail;
    if (resolveTail == null) {
      throw const VideoSourceCancelledException();
    }

    _activeRequest?.cancel();
    final request = _ResolveRequest();
    _activeRequest = request;

    final resolveFuture = resolveTail.then(
      (_) => _runResolve(
        request,
        episodeUrl,
        useLegacyParser: useLegacyParser,
        offset: offset,
        timeout: timeout,
      ),
    );
    _resolveTail = resolveFuture.then<void>((_) {}, onError: (_) {});
    return resolveFuture;
  }

  Future<VideoSource> _runResolve(
    _ResolveRequest request,
    String episodeUrl, {
    required bool useLegacyParser,
    required int offset,
    required Duration timeout,
  }) async {
    request.throwIfNotCurrent(_activeRequest);
    await ensureInitialized();
    request.throwIfNotCurrent(_activeRequest);

    var didStartLoad = false;
    try {
      final parserFuture = _webview!.onVideoURLParser.first.timeout(
        timeout,
        onTimeout: () {
          request.throwIfNotCurrent(_activeRequest);
          throw VideoSourceTimeoutException(timeout);
        },
      );
      final cancelFuture = request.cancelled.then<(String, int)>((_) {
        throw const VideoSourceCancelledException();
      });

      didStartLoad = true;
      await _webview!.loadUrl(
        episodeUrl,
        useLegacyParser,
        offset: offset,
      );
      request.throwIfNotCurrent(_activeRequest);

      final event = await Future.any([parserFuture, cancelFuture]);
      request.throwIfNotCurrent(_activeRequest);

      return VideoSource(
        url: event.$1,
        offset: event.$2,
        type: VideoSourceType.online,
      );
    } catch (error) {
      if (error is VideoSourceCancelledException) rethrow;
      request.throwIfNotCurrent(_activeRequest);
      rethrow;
    } finally {
      if (didStartLoad) {
        await _webview?.unloadPage();
      }
      if (identical(_activeRequest, request)) {
        _activeRequest = null;
      }
    }
  }

  @override
  void cancel() {
    _activeRequest?.cancel();
  }

  @override
  Future<void> dispose() async {
    final resolveTail = _resolveTail;
    _resolveTail = null;
    cancel();
    await resolveTail;
    try {
      await _initialization;
    } catch (_) {}
    _activeRequest = null;
    _logSubscription?.cancel();
    _logSubscription = null;
    if (!_logController.isClosed) {
      await _logController.close();
    }
    await _webview?.dispose();
    _webview = null;
  }
}

class _ResolveRequest {
  final Completer<void> _cancelled = Completer<void>();

  Future<void> get cancelled => _cancelled.future;

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }

  void throwIfNotCurrent(_ResolveRequest? current) {
    if (_cancelled.isCompleted || !identical(current, this)) {
      throw const VideoSourceCancelledException();
    }
  }
}
