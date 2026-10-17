import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// 基于公开的底层 TLS API 实现 Socket 读写流。
/// 保留原始 TCP 句柄，使连接器能在所属请求取消时立即终止握手。
class FlowSecureSocket extends Stream<Uint8List> implements SecureSocket {
  FlowSecureSocket(this._raw) {
    _input = StreamController<Uint8List>(
        sync: true,
        onListen: () => _raw.readEventsEnabled = true,
        onPause: () => _raw.readEventsEnabled = false,
        onResume: () => _raw.readEventsEnabled = true,
        onCancel: destroy);
    _sink = IOSink(_SecureSinkConsumer(this));
    unawaited(_sink.done.then<void>((_) {}, onError: (_) {}));
    _raw.readEventsEnabled = false;
    _raw.writeEventsEnabled = false;
    _raw.listen(_event, onError: (Object error, StackTrace stack) {
      if (!_input.isClosed) _input.addError(error, stack);
      destroy();
    }, onDone: destroy);
  }

  final RawSecureSocket _raw;
  late final StreamController<Uint8List> _input;
  late final IOSink _sink;
  Completer<void>? _writable;
  bool _destroyed = false;

  void _event(RawSocketEvent event) {
    if (_destroyed) return;
    if (event == RawSocketEvent.read) {
      final bytes = _raw.read();
      if (bytes != null && !_input.isClosed) _input.add(bytes);
    } else if (event == RawSocketEvent.write) {
      final writable = _writable;
      _writable = null;
      if (writable != null && !writable.isCompleted) writable.complete();
    } else if (event == RawSocketEvent.readClosed) {
      if (!_input.isClosed) unawaited(_input.close());
    } else if (event == RawSocketEvent.closed) {
      destroy();
    }
  }

  Future<void> _writeBytes(List<int> bytes) async {
    var offset = 0;
    while (offset < bytes.length) {
      if (_destroyed) throw const SocketException('TLS socket closed');
      final written = _raw.write(bytes, offset, bytes.length - offset);
      offset += written;
      if (written == 0) {
        final writable = _writable = Completer<void>();
        _raw.writeEventsEnabled = true;
        await writable.future;
      }
    }
  }

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _input.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  void destroy() {
    if (_destroyed) return;
    _destroyed = true;
    final writable = _writable;
    _writable = null;
    if (writable != null && !writable.isCompleted) {
      writable.completeError(const SocketException('TLS socket closed'));
    }
    unawaited(_raw.close());
    if (!_input.isClosed) unawaited(_input.close());
  }

  @override
  X509Certificate? get peerCertificate => _raw.peerCertificate;
  @override
  String? get selectedProtocol => _raw.selectedProtocol;
  @override
  InternetAddress get address => _raw.address;
  @override
  InternetAddress get remoteAddress => _raw.remoteAddress;
  @override
  int get port => _raw.port;
  @override
  int get remotePort => _raw.remotePort;
  @override
  bool setOption(SocketOption option, bool enabled) =>
      _raw.setOption(option, enabled);
  @override
  Uint8List getRawOption(RawSocketOption option) => _raw.getRawOption(option);
  @override
  void setRawOption(RawSocketOption option) => _raw.setRawOption(option);
  @override
  void renegotiate(
      {bool useSessionCache = true,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false}) {}
  @override
  Encoding get encoding => _sink.encoding;
  @override
  set encoding(Encoding value) => _sink.encoding = value;
  @override
  void add(List<int> data) => _sink.add(data);
  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _sink.addError(error, stackTrace);
  @override
  Future<void> addStream(Stream<List<int>> stream) => _sink.addStream(stream);
  @override
  Future<void> flush() => _sink.flush();
  @override
  Future<void> close() => _sink.close();
  @override
  Future<void> get done => _sink.done;
  @override
  void write(Object? object) => _sink.write(object);
  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _sink.writeAll(objects, separator);
  @override
  void writeln([Object? object = '']) => _sink.writeln(object);
  @override
  void writeCharCode(int charCode) => _sink.writeCharCode(charCode);

  // Socket 包含库私有的分离操作。此套接字已完成 TLS 升级，不会再次升级；
  // 所有公开的 Socket/IOSink 成员均已实现。
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SecureSinkConsumer implements StreamConsumer<List<int>> {
  _SecureSinkConsumer(this.socket);
  final FlowSecureSocket socket;
  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final bytes in stream) {
      await socket._writeBytes(bytes);
    }
  }

  @override
  Future<void> close() async {
    if (!socket._destroyed) socket._raw.shutdown(SocketDirection.send);
  }
}
