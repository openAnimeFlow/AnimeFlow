import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 内置地址仅作为候选，不代表排名或已经验证可用的路由。
class FlowEndpointCandidates {
  FlowEndpointCandidates._(List<String> addresses, List<int> rejectedLines)
      : addresses = List.unmodifiable(addresses),
        rejectedLines = List.unmodifiable(rejectedLines),
        _addressSet = Set.unmodifiable(addresses),
        hash = _hash(addresses);

  factory FlowEndpointCandidates.parse(String text) {
    final addresses = <String>[];
    final rejectedLines = <int>[];
    final seen = <String>{};
    final normalized = text.startsWith('\uFEFF') ? text.substring(1) : text;
    final lines = const LineSplitter().convert(normalized);
    for (var index = 0; index < lines.length; index++) {
      final address = lines[index].trim();
      if (address.isEmpty) continue;
      if (!isAllowedAddress(address)) {
        rejectedLines.add(index + 1);
      } else if (seen.add(address)) {
        addresses.add(address);
      }
    }
    return FlowEndpointCandidates._(addresses, rejectedLines);
  }

  final List<String> addresses;

  /// 行号从 1 开始；日志中不输出格式错误的原始文本。
  final List<int> rejectedLines;
  final Set<String> _addressSet;

  /// 规范化地址集合的哈希值：空白字符或顺序变化不会使缓存失效。
  final String hash;

  bool contains(String address) => _addressSet.contains(address);

  static String _hash(List<String> addresses) {
    final sorted = addresses.toList()..sort();
    return sha256.convert(utf8.encode(sorted.join('\n'))).toString();
  }

  static bool isAllowedAddress(String address) {
    final value = _ipv4Value(address);
    if (value == null) return false;
    return _cloudflareRanges.any((range) {
      final mask = (0xffffffff << (32 - range.$2)) & 0xffffffff;
      return (value & mask) == (range.$1 & mask);
    });
  }

  static int? _ipv4Value(String address) {
    final octets = address.split('.');
    if (octets.length != 4) return null;
    var value = 0;
    for (final octet in octets) {
      // 拒绝主机名、CIDR 网段、端口、其他编码形式及前导零。
      if (!_octetPattern.hasMatch(octet)) return null;
      final number = int.parse(octet);
      if (number > 255) return null;
      value = (value << 8) | number;
    }
    return value;
  }

  static final _octetPattern = RegExp(r'^(0|[1-9][0-9]{0,2})$');

  // Cloudflare 公布的 HTTP 代理 IPv4 网段，核对日期：2026-10-15。
  // https://www.cloudflare.com/ips-v4
  // 此白名单同时排除了私有、回环、链路本地及组播地址。
  static const _cloudflareRanges = <(int, int)>[
    (0xadf53000, 20), // 173.245.48.0/20
    (0x6715f400, 22), // 103.21.244.0/22
    (0x6716c800, 22), // 103.22.200.0/22
    (0x671f0400, 22), // 103.31.4.0/22
    (0x8d654000, 18), // 141.101.64.0/18
    (0x6ca2c000, 18), // 108.162.192.0/18
    (0xbe5df000, 20), // 190.93.240.0/20
    (0xbc726000, 20), // 188.114.96.0/20
    (0xc5eaf000, 22), // 197.234.240.0/22
    (0xc6298000, 17), // 198.41.128.0/17
    (0xa29e0000, 15), // 162.158.0.0/15
    (0x68100000, 13), // 104.16.0.0/13
    (0x68180000, 14), // 104.24.0.0/14
    (0xac400000, 13), // 172.64.0.0/13
    (0x83004800, 22), // 131.0.72.0/22
  ];
}
