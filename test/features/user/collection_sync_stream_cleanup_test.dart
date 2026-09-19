import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_flow/features/user/data/repository/collection_sync_repository.dart';

class CountingCancelToken extends CancelToken {
  int cancellations = 0;
  @override
  void cancel([Object? reason]) {
    cancellations++;
    super.cancel(reason);
  }
}

void main() {
  test('stream failure preserves the cancellation already made by its owner',
      () async {
    final token = CountingCancelToken();
    final bytes = StreamController<Uint8List>();
    final repo = CollectionSyncRepository(
        openEvents: (_) async => ResponseBody(bytes.stream, 200));
    final done = Completer<void>();
    repo.events(token).listen((_) {}, onError: (Object error) {
      token.cancel('owner closed');
    }, onDone: done.complete);
    bytes.addError(StateError('connection lost'));
    await bytes.close();
    await done.future;
    expect(token.cancellations, 1);
    expect(token.cancelError?.error, 'owner closed');
  });

  test('subscription cancellation releases an otherwise uncancelled connection',
      () async {
    final token = CountingCancelToken();
    final started = Completer<void>();
    final bytes = StreamController<Uint8List>(onListen: started.complete);
    final repo = CollectionSyncRepository(
        openEvents: (_) async => ResponseBody(bytes.stream, 200));
    final subscription = repo.events(token).listen((_) {});
    await started.future;
    await subscription.cancel();
    expect(token.cancellations, 1);
    expect(token.cancelError?.error, 'collection stream closed');
    await bytes.close();
  });

  test('page cancellation followed by subscription cleanup cancels only once',
      () async {
    final token = CountingCancelToken();
    final started = Completer<void>();
    final bytes = StreamController<Uint8List>(onListen: started.complete);
    final repo = CollectionSyncRepository(
        openEvents: (_) async => ResponseBody(bytes.stream, 200));
    final subscription = repo.events(token).listen((_) {});
    await started.future;
    token.cancel('page closed');
    await subscription.cancel();
    expect(token.cancellations, 1);
    expect(token.cancelError?.error, 'page closed');
    await bytes.close();
  });
}
