import 'dart:async';
import 'dart:collection';

import 'package:anime_flow/features/play/presentation/providers/video_source_service.dart';
import 'package:anime_flow/features/play/presentation/providers/webview_video_source_provider.dart';

class VideoSourceResolveRequest {
  const VideoSourceResolveRequest({
    required this.episodeUrl,
    this.useLegacyParser = false,
    this.offset = 0,
    this.timeout = const Duration(seconds: 30),
  });

  final String episodeUrl;
  final bool useLegacyParser;
  final int offset;
  final Duration timeout;
}

abstract interface class IVideoSourceResolverPool {
  Future<VideoSource> resolve(VideoSourceResolveRequest request);

  void cancelAll();

  void dispose();
}

class VideoSourceResolverPool implements IVideoSourceResolverPool {
  VideoSourceResolverPool({
    int workerCount = 2,
    IVideoSourceProvider Function()? providerFactory,
  })  : _workerCount = workerCount < 1 ? 1 : workerCount,
        _providerFactory =
            providerFactory ?? (() => WebViewVideoSourceProvider());

  final int _workerCount;
  final IVideoSourceProvider Function() _providerFactory;
  final _queue = Queue<_QueuedResolve>();
  final _workers = <_ResolverWorker>[];
  var _disposed = false;

  @override
  Future<VideoSource> resolve(VideoSourceResolveRequest request) {
    if (_disposed) {
      return Future<VideoSource>.error(StateError('resolver pool disposed'));
    }

    final queued = _QueuedResolve(request);
    _queue.add(queued);
    _pump();
    return queued.completer.future;
  }

  @override
  void cancelAll() {
    for (final queued in _queue) {
      if (!queued.completer.isCompleted) {
        queued.completer.completeError(const VideoSourceCancelledException());
      }
    }
    _queue.clear();

    for (final worker in _workers) {
      worker.provider.cancel();
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    cancelAll();
    for (final worker in _workers) {
      worker.provider.dispose();
    }
    _workers.clear();
  }

  void _pump() {
    while (_queue.isNotEmpty && _activeWorkers < _workerCount) {
      final worker = _idleWorker() ?? _createWorker();
      final queued = _queue.removeFirst();
      worker.isBusy = true;
      unawaited(_run(worker, queued));
    }
  }

  Future<void> _run(_ResolverWorker worker, _QueuedResolve queued) async {
    try {
      final source = await worker.provider.resolve(
        queued.request.episodeUrl,
        useLegacyParser: queued.request.useLegacyParser,
        offset: queued.request.offset,
        timeout: queued.request.timeout,
      );
      if (!queued.completer.isCompleted) {
        queued.completer.complete(source);
      }
    } catch (error, stackTrace) {
      if (!queued.completer.isCompleted) {
        queued.completer.completeError(error, stackTrace);
      }
    } finally {
      worker.isBusy = false;
      if (_disposed) {
        worker.provider.dispose();
      } else {
        _pump();
      }
    }
  }

  int get _activeWorkers => _workers.where((worker) => worker.isBusy).length;

  _ResolverWorker? _idleWorker() {
    for (final worker in _workers) {
      if (!worker.isBusy) {
        return worker;
      }
    }
    return null;
  }

  _ResolverWorker _createWorker() {
    final worker = _ResolverWorker(_providerFactory());
    _workers.add(worker);
    return worker;
  }
}

class _QueuedResolve {
  _QueuedResolve(this.request);

  final VideoSourceResolveRequest request;
  final Completer<VideoSource> completer = Completer<VideoSource>();
}

class _ResolverWorker {
  _ResolverWorker(this.provider);

  final IVideoSourceProvider provider;
  var isBusy = false;
}
