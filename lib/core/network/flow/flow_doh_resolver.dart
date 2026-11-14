import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'transport/flow_pinned_connection.dart';

/// 通过 Cloudflare DoH 解析 Flow 的端点，而不依赖系统 DNS。
///
/// 它只依赖传输层（[FlowPinnedConnection]）来获得“固定 IP + TLS”的 HTTP 客户端：
/// 1.1.1.1 直连、证书按 `cloudflare-dns.com` 校验、`allowDnsFallback: false`
/// 保证解析失败时不会绕回系统 DNS 造成自我递归。
/// 连接器只需拿到 [FlowHostResolve]（即 `resolve` 的方法引用）。
class FlowDohResolver {
  static const _dohHost = 'cloudflare-dns.com';
  static const _dohAddresses = ['1.1.1.1', '1.0.0.1'];
  static const _timeout = Duration(seconds: 2);
  final HttpClient _client = _createClient();
  Future<List<String>>? _pending;
  List<String> _cached = const [];
  DateTime _expiresAt = DateTime.fromMillisecondsSinceEpoch(0);

  static HttpClient _createClient() => FlowPinnedConnection(
        endpoint: Uri.https(_dohHost, '/dns-query'),
        addresses: _dohAddresses,
        allowDnsFallback: false,
        candidateTimeout: _timeout,
      ).createClient()
        ..connectionTimeout = _timeout;

  /// 解析 [host]；失败时返回空列表，并缓存成功结果至 TTL 上限。
  Future<List<String>> resolve(String host) {
    if (DateTime.now().isBefore(_expiresAt) && _cached.isNotEmpty) {
      return Future.value(_cached);
    }
    return _pending ??= _lookup(host)
        .timeout(_timeout, onTimeout: () => const <String>[])
        .whenComplete(() => _pending = null);
  }

  Future<List<String>> _lookup(String host) async {
    final answers = <String>[];
    var ttl = 600;
    for (final type in const ['A', 'AAAA']) {
      final uri = Uri.https(_dohHost, '/dns-query', {
        'name': host,
        'type': type,
      });
      try {
        final request = await _client.getUrl(uri).timeout(_timeout);
        request.headers.set(HttpHeaders.acceptHeader, 'application/dns-json');
        final response = await request.close().timeout(_timeout);
        if (response.statusCode != HttpStatus.ok) continue;
        final body = await utf8.decoder.bind(response).join().timeout(_timeout);
        final json = jsonDecode(body);
        if (json is! Map<String, dynamic> || json['Status'] != 0) continue;
        final records = json['Answer'];
        if (records is! List) continue;
        for (final record in records.whereType<Map<String, dynamic>>()) {
          final data = record['data'];
          final recordTtl = record['TTL'];
          if (data is String) {
            try {
              final address = InternetAddress(data);
              if (address.type == InternetAddressType.IPv4 ||
                  address.type == InternetAddressType.IPv6) {
                answers.add(address.address);
                if (recordTtl is int && recordTtl > 0 && recordTtl < ttl) {
                  ttl = recordTtl;
                }
              }
            } on FormatException {
              // Ignore malformed answer data.
            }
          }
        }
      } on Object {
        // Try the other address family; the pinned client never falls back to
        // system DNS, so a failure here simply means "no answer".
      }
    }
    final result = answers.toSet().toList(growable: false);
    if (result.isNotEmpty) {
      _cached = result;
      _expiresAt = DateTime.now().add(Duration(seconds: ttl.clamp(15, 600)));
    }
    return result;
  }

  void close() => _client.close(force: true);
}
