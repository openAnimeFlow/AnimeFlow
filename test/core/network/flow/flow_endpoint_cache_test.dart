import 'package:anime_flow/core/network/flow/flow_endpoint_cache.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_candidates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final endpoint = Uri.parse('https://ligg.top');
  final candidates =
      FlowEndpointCandidates.parse('172.66.214.245\n104.19.52.165');
  final now = DateTime.utc(2026, 10, 15, 12);

  FlowEndpointCache cache({DateTime? verifiedAt}) => FlowEndpointCache(
        host: endpoint.host,
        port: endpoint.port,
        candidateHash: candidates.hash,
        verifiedAt: verifiedAt ?? now.subtract(const Duration(minutes: 10)),
        measurements: const [
          FlowEndpointMeasurement(
              address: '104.19.52.165',
              latency: Duration(microseconds: 123456),
              successCount: 2),
        ],
        networkType: 'wifi',
      );

  FlowEndpointCache? validate(FlowEndpointCache value) => value.validatedFor(
        endpoint: endpoint,
        candidates: candidates,
        now: now,
      );

  test('round-trips Hive-compatible maps without losing measurement precision',
      () {
    final original = cache();
    final restored = FlowEndpointCache.fromMap(original.toMap())!;
    expect(restored.toMap(), original.toMap());
    expect(restored.measurements.single.latency.inMicroseconds, 123456);
    expect(restored.verifiedAt.isUtc, isTrue);
    expect(validate(restored), isNotNull);
    expect(() => restored.measurements.clear(), throwsUnsupportedError);
  });

  test('expires at six hours and rejects dates in the future', () {
    expect(validate(cache(verifiedAt: now.subtract(const Duration(hours: 6)))),
        isNull);
    expect(
        validate(cache(
            verifiedAt: now.subtract(
                const Duration(hours: 6) - const Duration(milliseconds: 1)))),
        isNotNull);
    expect(validate(cache(verifiedAt: now.add(const Duration(seconds: 1)))),
        isNull);
  });

  test('rejects incompatible metadata and unsupported cache formats', () {
    for (final entry in <MapEntry<String, Object?>>[
      const MapEntry('version', 2),
      const MapEntry('version', 1.0),
      const MapEntry('host', 'other.example'),
      const MapEntry('port', 8443),
      MapEntry('candidateHash', '0' * 64),
      const MapEntry('candidateHash', 'broken'),
      const MapEntry('verifiedAtMs', -1),
      const MapEntry('verifiedAtMs', 9223372036854775807),
      const MapEntry('measurements', 'not-a-list'),
    ]) {
      final raw = cache().toMap()..[entry.key] = entry.value;
      final parsed = FlowEndpointCache.fromMap(raw);
      expect(parsed == null ? null : validate(parsed), isNull,
          reason: entry.key);
    }
    for (final raw in [null, '', 1, [], <String, Object?>{}]) {
      expect(FlowEndpointCache.fromMap(raw), isNull);
    }
  });

  test('discards bad or removed entries while retaining valid primary/backup',
      () {
    final raw = cache().toMap();
    final measurement = cache().measurements.single.toMap();
    raw['measurements'] = [
      null,
      {...measurement, 'address': '127.0.0.1'},
      {...measurement, 'successCount': 0},
      {...measurement, 'latencyMicros': -1},
      {...measurement, 'latencyMicros': '100'},
      {...measurement, 'address': '104.18.55.113'}, // No longer in this pool.
      measurement,
      measurement,
    ];
    final restored = validate(FlowEndpointCache.fromMap(raw)!)!;
    expect(
        restored.measurements.map((item) => item.address), ['104.19.52.165']);

    raw['measurements'] = [
      null,
      {'address': 'invalid'}
    ];
    expect(FlowEndpointCache.fromMap(raw), isNull);
  });

  test('changed candidate set or non-HTTPS endpoint invalidates old cache', () {
    expect(
      cache().validatedFor(
          endpoint: endpoint,
          candidates: FlowEndpointCandidates.parse('172.66.214.245'),
          now: now),
      isNull,
    );
    expect(
      cache().validatedFor(
          endpoint: Uri.parse('http://ligg.top:443'),
          candidates: candidates,
          now: now),
      isNull,
    );
  });
}
