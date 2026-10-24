import 'dart:async';

import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/video_source/domain/video_source.dart';
import 'package:anime_flow/core/webview/video/video_webview_controller.dart';

/// Serial native parsing. A newer playback request supersedes the previous one.
class WebViewVideoSourceService implements IVideoSourceProvider {
  WebViewVideoSourceService({required this.controllerFactory});
  final VideoWebviewController Function() controllerFactory;
  Future<void> _tail = Future<void>.value();
  _ResolveOperation? _active;
  _ControllerSession? _session;
  final _retirements = <Future<void>>{};
  Future<void>? _disposal;

  @override
  Future<VideoSource> resolve(VideoSourceResolveRequest request) {
    if (_disposal != null || request.cancellation?.isCancelled == true) {
      return Future.error(const VideoSourceCancelledException());
    }
    cancel();
    final operation = _active = _ResolveOperation(request);
    final work = _tail.then((_) => _run(operation));
    _tail = work.then<void>((_) {}, onError: (Object error) {});
    return operation.wait(work);
  }

  Future<VideoSource> _run(_ResolveOperation operation) async {
    _ControllerSession? session;
    StreamSubscription<(String, int)>? subscription;
    Completer<(String, int)>? parsed;
    try {
      operation.check();
      operation.startTimeout();
      session = _session ??= _ControllerSession(controllerFactory());
      await operation.wait(session.nativeWork);
      operation.check();
      final source = parsed = Completer<(String, int)>();
      subscription = session.controller.onVideoURLParser.listen((event) {
        if (!source.isCompleted) source.complete(event);
      }, onError: (Object error, StackTrace stack) {
        if (!source.isCompleted) source.completeError(error, stack);
      }, onDone: () {
        if (!source.isCompleted) {
          source.completeError(const VideoSourceNotFoundException());
        }
      });
      // Attach handlers before loading: native events may arrive during loadUrl.
      final results = await operation.wait(Future.wait<Object?>([
        session.run(() => session!.controller.loadUrl(
            operation.request.episodeUrl, operation.request.useLegacyParser,
            offset: operation.request.offset)),
        source.future,
      ], eagerError: true));
      final event = results[1] as (String, int);
      if (event.$1.trim().isEmpty) throw const VideoSourceNotFoundException();
      await operation.wait(session.run(session.controller.unloadPage));
      operation.check();
      return VideoSource(
          url: event.$1, offset: event.$2, type: VideoSourceType.online);
    } catch (_) {
      if (session != null) {
        if (identical(_session, session)) _session = null;
        _retire(session);
      }
      rethrow;
    } finally {
      await subscription?.cancel();
      if (parsed != null && !parsed.isCompleted) {
        parsed.completeError(const VideoSourceCancelledException());
      }
      operation.finish();
      if (identical(_active, operation)) _active = null;
    }
  }

  void _retire(_ControllerSession session) {
    if (session.retired) return;
    session.retired = true;
    final cleanup = () async {
      // Native plugins cannot dispose safely while init/load is still running.
      try {
        await session.nativeWork;
      } catch (_) {}
      try {
        await session.controller.dispose();
      } catch (error) {
        LiggLogger().w('释放视频解析 WebView 失败 (${error.runtimeType})');
      }
    }();
    _retirements.add(cleanup);
    unawaited(cleanup.then((_) => _retirements.remove(cleanup)));
  }

  @override
  void cancel() => _active?.abort(const VideoSourceCancelledException());
  @override
  Future<void> dispose() => _disposal ??= _dispose();
  Future<void> _dispose() async {
    cancel();
    await _tail;
    final session = _session;
    _session = null;
    if (session != null) _retire(session);
    await Future.wait(_retirements.toList());
  }
}

class _ControllerSession {
  _ControllerSession(this.controller) {
    nativeWork = Future<void>.sync(controller.init);
  }
  final VideoWebviewController controller;
  late Future<void> nativeWork;
  bool retired = false;
  Future<void> run(Future<void> Function() action) =>
      nativeWork = Future.sync(action);
}

class _ResolveOperation {
  _ResolveOperation(this.request) {
    final cancellation = request.cancellation;
    if (cancellation != null) {
      _subscription = cancellation.onCancel
          .listen((_) => abort(const VideoSourceCancelledException()));
      if (cancellation.isCancelled) {
        abort(const VideoSourceCancelledException());
      }
    }
  }
  final VideoSourceResolveRequest request;
  final _aborted = Completer<void>();
  Exception? _error;
  Timer? _timer;
  StreamSubscription<void>? _subscription;
  void startTimeout() {
    _timer = Timer(request.timeout,
        () => abort(VideoSourceTimeoutException(request.timeout)));
  }

  void check() {
    if (_error != null) throw _error!;
  }

  void abort(Exception error) {
    if (_error != null) return;
    _error = error;
    _aborted.complete();
  }

  Future<T> wait<T>(Future<T> work) => Future.any([
        work,
        _aborted.future.then<T>((_) => throw _error!),
      ]);
  void finish() {
    _timer?.cancel();
    unawaited(_subscription?.cancel());
  }
}
