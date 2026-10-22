@Tags(['architecture'])
library;

import 'package:test/test.dart';
import 'package:anime_flow_architecture_guard/src/legacy_checks.dart';
import 'package:anime_flow_architecture_guard/src/model.dart';

const source = 'lib/features/a/application/service.dart';
const target = 'lib/shared/widgets/toast.dart';
const violation = ArchitectureViolation(
  'R03',
  source,
  target,
  'import',
  1,
  'UI',
);
final today = DateTime.utc(2026, 10, 22);

Map<String, dynamic> register({String rule = 'R03', String kind = 'import'}) =>
    {
      'schemaVersion': 1,
      'violations': [
        {
          'rule': rule,
          'source': source,
          'target': target,
          'kind': kind,
          'reason': '已有依赖，后续清理',
          'owner': 'feature:a',
          'cleanupTask': '拆分 UI 提示',
          'reviewBy': '2026-11-22',
        },
      ],
    };

void main() {
  test('exact current edges pass without modifying the register', () {
    final json = register();
    final result = compareLegacy(
      [violation],
      json,
      sources: {source},
      now: today,
    );
    expect(result.passes, isTrue);
    expect(result.registered, 1);
    expect(json, register());
  });

  test('new violations and resolved entries both fail', () {
    final fresh = compareLegacy(
      [violation],
      {'schemaVersion': 1, 'violations': []},
      sources: {source},
      now: today,
    );
    expect(fresh.passes, isFalse);
    expect(fresh.newViolations.single.key, violation.key);
    final stale = compareLegacy([], register(), sources: {source}, now: today);
    expect(stale.passes, isFalse);
    expect(stale.stale, {violation.key});
  });

  test('cycles can retain exact existing dependency edges', () {
    const cycle = ArchitectureViolation(
      'R07',
      source,
      target,
      'import',
      1,
      'cycle',
    );
    expect(
      compareLegacy(
        [cycle],
        register(rule: 'R07'),
        sources: {source},
        now: today,
      ).passes,
      isTrue,
    );
  });

  for (final rule in [
    'R01',
    'R02',
    'R04',
    'R05',
    'R06',
    'R08',
    'R09',
    'UNKNOWN',
  ]) {
    test('disabled rule $rule cannot remain in the register', () {
      expect(
        () => compareLegacy(
          [],
          register(rule: rule),
          sources: {source},
          now: today,
        ),
        throwsStateError,
      );
    });
  }

  test('missing metadata, duplicate, expired or invalid entries fail', () {
    for (final field in ['reason', 'owner', 'cleanupTask', 'reviewBy']) {
      final json = register();
      (json['violations'] as List).single.remove(field);
      expect(
        () => compareLegacy([], json, sources: {source}, now: today),
        throwsStateError,
      );
    }
    final duplicate = register();
    (duplicate['violations'] as List).add(
      (duplicate['violations'] as List).single,
    );
    expect(
      () => compareLegacy([], duplicate, sources: {source}, now: today),
      throwsStateError,
    );
    expect(
      () => compareLegacy(
        [],
        register(),
        sources: {source},
        now: DateTime.utc(2026, 11, 23),
      ),
      throwsStateError,
    );
    expect(
      () => compareLegacy([], register(), sources: {}, now: today),
      throwsStateError,
    );
    expect(
      () => compareLegacy(
        [],
        register(kind: 'type'),
        sources: {source},
        now: today,
      ),
      throwsStateError,
    );
    expect(
      () => compareLegacy(
        [],
        {'schemaVersion': 1, 'violations': null},
        sources: {source},
        now: today,
      ),
      throwsStateError,
    );
  });
}
