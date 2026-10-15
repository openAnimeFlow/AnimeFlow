import 'flow_endpoint_candidates.dart';

/// A previous measurement is only a hint for revalidation on the current network.
class FlowEndpointMeasurement {
  const FlowEndpointMeasurement({
    required this.address,
    required this.latency,
    required this.successCount,
  });

  final String address;
  final Duration latency;
  final int successCount;

  Map<String, Object> toMap() => {
        'address': address,
        'latencyMicros': latency.inMicroseconds,
        'successCount': successCount,
      };

  static FlowEndpointMeasurement? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final address = raw['address'];
    final latency = raw['latencyMicros'];
    final successes = raw['successCount'];
    if (address is! String ||
        !FlowEndpointCandidates.isAllowedAddress(address) ||
        latency is! int ||
        latency < 0 ||
        successes is! int ||
        successes < 1) {
      return null;
    }
    return FlowEndpointMeasurement(
      address: address,
      latency: Duration(microseconds: latency),
      successCount: successes,
    );
  }
}

class FlowEndpointCache {
  FlowEndpointCache({
    required this.host,
    required this.port,
    required this.candidateHash,
    required DateTime verifiedAt,
    required List<FlowEndpointMeasurement> measurements,
    this.networkType,
  })  : verifiedAt = verifiedAt.toUtc(),
        measurements = List.unmodifiable(measurements);

  static const version = 1;
  static const lifetime = Duration(hours: 6);

  final String host;
  final int port;
  final String candidateHash;
  final DateTime verifiedAt;

  /// Preserves the previous primary/backup order, not current-network validity.
  final List<FlowEndpointMeasurement> measurements;
  final String? networkType;

  Map<String, Object?> toMap() => {
        'version': version,
        'host': host,
        'port': port,
        'candidateHash': candidateHash,
        'verifiedAtMs': verifiedAt.millisecondsSinceEpoch,
        'measurements': measurements.map((item) => item.toMap()).toList(),
        if (networkType != null) 'networkType': networkType,
      };

  static FlowEndpointCache? fromMap(Object? raw) {
    if (raw is! Map || raw['version'] is! int || raw['version'] != version) {
      return null;
    }
    final host = raw['host'];
    final port = raw['port'];
    final hash = raw['candidateHash'];
    final verifiedAtMs = raw['verifiedAtMs'];
    final entries = raw['measurements'];
    final networkType = raw['networkType'];
    if (host is! String ||
        host.isEmpty ||
        port is! int ||
        port < 1 ||
        port > 65535 ||
        hash is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
        verifiedAtMs is! int ||
        verifiedAtMs < 0 ||
        entries is! List ||
        (networkType != null && networkType is! String)) {
      return null;
    }
    final measurements = <FlowEndpointMeasurement>[];
    final seen = <String>{};
    for (final entry in entries) {
      final measurement = FlowEndpointMeasurement.fromMap(entry);
      if (measurement != null && seen.add(measurement.address)) {
        measurements.add(measurement);
      }
    }
    if (measurements.isEmpty) return null;
    try {
      return FlowEndpointCache(
        host: host,
        port: port,
        candidateHash: hash,
        verifiedAt:
            DateTime.fromMillisecondsSinceEpoch(verifiedAtMs, isUtc: true),
        measurements: measurements,
        networkType: networkType as String?,
      );
    } on ArgumentError {
      return null;
    }
  }

  /// Reject incompatible/expired metadata and remove obsolete individual IPs.
  FlowEndpointCache? validatedFor({
    required Uri endpoint,
    required FlowEndpointCandidates candidates,
    required DateTime now,
  }) {
    final age = now.toUtc().difference(verifiedAt);
    if (endpoint.scheme != 'https' ||
        host != endpoint.host ||
        port != endpoint.port ||
        candidateHash != candidates.hash ||
        age.isNegative ||
        age >= lifetime) {
      return null;
    }
    final eligible = measurements
        .where((item) => candidates.contains(item.address))
        .take(3)
        .toList();
    if (eligible.isEmpty) return null;
    return FlowEndpointCache(
      host: host,
      port: port,
      candidateHash: candidateHash,
      verifiedAt: verifiedAt,
      measurements: eligible,
      networkType: networkType,
    );
  }
}
