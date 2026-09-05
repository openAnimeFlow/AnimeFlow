/// Serializes native player work without letting a failure block later work.
class PlayerOperationQueue {
  PlayerOperationQueue({required this.ensureReady});

  final void Function() ensureReady;
  Future<void> _tail = Future<void>.value();

  /// Wait for already submitted operations before releasing native resources.
  Future<void> get drained => _tail;

  Future<T> run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) {
      ensureReady();
      return operation();
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}
