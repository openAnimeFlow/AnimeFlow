import 'dart:async';
import 'dart:io';

import 'transport/flow_pinned_connection.dart';

export 'transport/flow_connection_scope.dart';

/// Flow 业务侧的连接器门面：为 Dio 适配器与探测器提供“固定 IP 建连”客户端。
///
/// 依赖方向固定为单向：
/// ```
/// flow_http_client_adapter / flow_endpoint_probe
///        └── FlowConnectionConnector ──┐
/// flow_doh_resolver ───────────────────┴──> transport/ (dialer + pinned connection)
/// ```
/// 传输层只关心 [FlowHostResolve] 这个解析回调，具体解析器（如 Cloudflare DoH）
class FlowConnectionConnector {
  FlowConnectionConnector({
    required Uri endpoint,
    List<String> addresses = const [],
    bool allowDnsFallback = true,
    Duration candidateTimeout = const Duration(milliseconds: 1500),
    SecurityContext? securityContext,
    FlowHostResolve? hostResolver,
    void Function(String address)? onAddressFailure,
    bool Function(String address)? isAddressAvailable,
  }) : _connection = FlowPinnedConnection(
          endpoint: endpoint,
          addresses: addresses,
          allowDnsFallback: allowDnsFallback,
          candidateTimeout: candidateTimeout,
          securityContext: securityContext,
          resolver: hostResolver,
          onAddressFailure: onAddressFailure,
          isAddressAvailable: isAddressAvailable,
        );

  final FlowPinnedConnection _connection;

  Uri get endpoint => _connection.endpoint;

  bool matches(Uri uri) => _connection.matches(uri);

  HttpClient createClient() => _connection.createClient();

  Future<ConnectionTask<Socket>> connect(
          Uri uri, String? proxyHost, int? proxyPort) =>
      _connection.connect(uri, proxyHost, proxyPort);
}
