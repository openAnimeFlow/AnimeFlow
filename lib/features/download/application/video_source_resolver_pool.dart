import 'dart:async';
import 'dart:collection';

import 'package:anime_flow/core/video_source/domain/video_source.dart';

/// Bounded workers using injected resolvers, independent of native plugins.
class VideoSourceResolverPool implements IVideoSourceResolverPool {
  VideoSourceResolverPool(
      {int workerCount = 2,
      required VideoSourceProviderFactory providerFactory})
      : _workerCount = workerCount < 1 ? 1 : workerCount,
        _providerFactory = providerFactory;
  final int _workerCount;
  final VideoSourceProviderFactory _providerFactory;
  final _queue = Queue<_QueuedResolve>();
  final _workers = <_ResolverWorker>[];
  final _retirements = <Future<void>>{};
  Future<void>? _disposal;

  @override
  Future<VideoSource> resolve(VideoSourceResolveRequest request) {
    if (_disposal != null) {
      return Future.error(StateError('resolver pool disposed'));
    }
    final queued = _QueuedResolve(request);
    _queue.add(queued);
    _pump();
    return queued.completer.future;
  }

  @override
  void cancelAll() {
    for (final queued in _queue) {
      queued._abort(const VideoSourceCancelledException());
    }
    _queue.clear();
    for (final worker in _workers.toList()) {
      worker.active?._abort(const VideoSourceCancelledException());
    }
  }

  @override
  Future<void> dispose() => _disposal ??= _dispose();

  Future<void> _dispose() async {
    cancelAll();
    final workers = _workers.toList();
    _workers.clear();
    for (final worker in workers) {
      _retire(worker);
    }
    await Future.wait(_retirements.toList());
  }

  void _retire(_ResolverWorker worker) {
    if (worker.retired) return;
    worker.retired = true;
    worker.provider.cancel();
    final disposal = Future<void>.sync(worker.provider.dispose);
    _retirements.add(disposal);
    unawaited(disposal.then<void>((_) => _retirements.remove(disposal),
        onError: (Object error, StackTrace stack) {}));
  }

  void _pump() {
    if (_disposal != null) return;
    while (_queue.isNotEmpty) {
      if (_queue.first.completer.isCompleted) {
        _queue.removeFirst();
        continue;
      }
      _ResolverWorker? worker;
      for (final candidate in _workers) {
        if (candidate.active == null) {
          worker = candidate;
          break;
        }
      }
      if (worker == null) {
        if (_workers.length >= _workerCount) return;
        try {
          worker = _ResolverWorker(_providerFactory());
          _workers.add(worker);
        } catch (error, stack) {
          final queued = _queue.removeFirst();
          queued.completer.completeError(error, stack);
          queued._finish();
          continue;
        }
      }
      final queued = _queue.removeFirst();
      worker.active = queued;
      unawaited(_run(worker, queued));
    }
  }

  Future<void> _run(_ResolverWorker worker, _QueuedResolve queued) async {
    final timer = Timer(
        queued.request.timeout,
        () =>
            queued._abort(VideoSourceTimeoutException(queued.request.timeout)));
    try {
      final source = await Future.any([
        Future<VideoSource>.sync(() => worker.provider
            .resolve(queued.request.withCancellation(queued.cancellation))),
        queued.aborted.future.then<VideoSource>((_) => throw queued.error!),
      ]);
      if (!queued.completer.isCompleted) queued.completer.complete(source);
    } catch (error, stack) {
      if (!queued.completer.isCompleted) {
        queued.completer.completeError(error, stack);
      }
    } finally {
      timer.cancel();
      queued._finish();
      worker.active = null;
      if (queued.error != null) {
        _workers.remove(worker);
        _retire(worker);
      }
      _pump();
    }
  }
}

class _QueuedResolve {
  _QueuedResolve(this.request) {
    final token = request.cancellation;
    if (token != null) {
      _subscription = token.onCancel
          .listen((_) => _abort(const VideoSourceCancelledException()));
      if (token.isCancelled) _abort(const VideoSourceCancelledException());
    }
  }

  final VideoSourceResolveRequest request;
  final completer = Completer<VideoSource>();
  final aborted = Completer<void>();
  final cancellation = VideoSourceCancellation();
  StreamSubscription<void>? _subscription;
  Exception? error;

  void _abort(Exception reason) {
    if (completer.isCompleted) return;
    error = reason;
    cancellation.cancel();
    aborted.complete();
    completer.completeError(reason);
    _finish();
  }

  void _finish() {
    unawaited(_subscription?.cancel());
  }
}

class _ResolverWorker {
  _ResolverWorker(this.provider);

  final IVideoSourceProvider provider;
  _QueuedResolve? active;
  bool retired = false;
}
