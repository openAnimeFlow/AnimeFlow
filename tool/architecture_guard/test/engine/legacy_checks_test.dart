@Tags(['architecture'])
library;

import 'dart:io';

import 'package:test/test.dart';

import 'package:anime_flow_architecture_guard/src/legacy_checks.dart';
import 'package:anime_flow_architecture_guard/src/model.dart';
import 'package:anime_flow_architecture_guard/architecture_spec.dart';

const source = 'lib/features/a/application/service.dart';
const target = 'lib/features/a/presentation/widgets/view.dart';
const violation = ArchitectureViolation(
  'R03',
  source,
  target,
  'import',
  1,
  'move business state',
);
Map<String, dynamic> register({
  String rule = 'R03',
  String destination = target,
  String review = '2030-01-01',
}) => {
  'schemaVersion': 1,
  'violations': [
    {
      'rule': rule,
      'source': source,
      'target': destination,
      'kind': 'import',
      'reason': 'Existing responsibility awaiting migration',
      'owner': 'feature:a',
      'cleanupTask': 'application separation',
      'reviewBy': review,
    },
  ],
};

void main() {
  test(
    'migrated business rules and incoming API boundaries cannot be frozen',
    () {
      final spec = ArchitectureSpec(
        [],
        strictScopes: {
          'R03': {'lib/features/a/application/**.dart'},
          'R06': {'lib/features/a/**.dart'},
        },
      );
      expect(
        () => compareLegacy(
          [violation],
          register(),
          sources: {source},
          spec: spec,
        ),
        throwsStateError,
      );
      final incoming = register(rule: 'R06', destination: source);
      final raw = (incoming['violations'] as List).single as Map;
      raw['source'] = 'lib/features/b/application/service.dart';
      expect(
        () => compareLegacy(
          [],
          incoming,
          sources: {raw['source'] as String},
          spec: spec,
        ),
        throwsStateError,
      );
      // Unmigrated source/rule remains governed by exact legacy identities.
      expect(
        compareLegacy(
          [violation],
          register(),
          sources: {source},
          spec: ArchitectureSpec([]),
        ).passes,
        isTrue,
      );
    },
  );
  test('project policy closes user/auth business without hiding routing debt', () {
    final spec = projectArchitecture();
    const implementation =
        'lib/core/video_source/infrastructure/webview_video_source_service.dart';
    expect(
      () => compareLegacy(
        [],
        register(rule: 'R04', destination: implementation),
        sources: {source},
        spec: spec,
      ),
      throwsStateError,
    );
    expect(
      spec.isStrict('R07', 'lib/core/network/interceptors/new.dart'),
      isTrue,
    );
    for (final feature in ['auth', 'user']) {
      for (final rule in ['R03', 'R06', 'R07', 'R09']) {
        expect(
          spec.isStrict(rule, 'lib/features/$feature/application/new.dart'),
          isTrue,
        );
      }
    }
    expect(
      spec.isStrict(
        'R07',
        'lib/features/user/presentation/pages/user_page.dart',
      ),
      isFalse,
    );
    expect(
      spec.modules.singleWhere((m) => m.name == 'auth').dependencies,
      isEmpty,
    );
    expect(spec.modules.singleWhere((m) => m.name == 'user').dependencies, {
      'auth',
    });
    expect(
      () => ArchitectureSpec(
        spec.modules,
        strictScopes: {
          'R03': {'lib/missing/**.dart'},
        },
      ).validate({'lib/main.dart'}),
      throwsStateError,
    );
  });
  final date = DateTime.utc(2026, 10, 22);
  LegacyResult compare(
    List<ArchitectureViolation> values,
    Map<String, dynamic> json,
  ) => compareLegacy(values, json, sources: {source}, now: date);
  test('line movement does not change registered dependency identity', () {
    const moved = ArchitectureViolation(
      'R03',
      source,
      target,
      'import',
      99,
      'new wording',
    );
    expect(compare([moved], register()).passes, isTrue);
  });
  test('same-count replacement reports new edge and stale entry', () {
    final result = compare([violation], register(destination: '$target.other'));
    expect(result.newViolations.length, 1);
    expect(result.stale.length, 1);
    expect(result.passes, isFalse);
  });
  test('fixed issues must be pruned explicitly', () {
    expect(compare([], register()).stale.length, 1);
  });
  for (final rule in ['R01', 'R02', 'R08', 'UNKNOWN']) {
    test('strict/unknown rule $rule cannot be registered', () {
      expect(() => compare([], register(rule: rule)), throwsStateError);
    });
  }
  test('duplicates, unknown fields and missing ownership fail', () {
    final duplicate = register();
    (duplicate['violations'] as List).add(
      (duplicate['violations'] as List).single,
    );
    expect(() => compare([violation], duplicate), throwsStateError);
    final missing = register();
    ((missing['violations'] as List).single as Map).remove('owner');
    expect(() => compare([violation], missing), throwsStateError);
    expect(
      () => compare([], {...register(), 'allowAll': true}),
      throwsStateError,
    );
  });
  test('expired and invalid review dates fail', () {
    for (final review in ['2026-10-21', '2026-02-31', 'never']) {
      expect(() => compare([], register(review: review)), throwsStateError);
    }
  });
  test('unknown source and malformed register fail', () {
    expect(
      () => compareLegacy([], register(), sources: {}, now: date),
      throwsStateError,
    );
    expect(
      () => compare([], {'schemaVersion': 2, 'violations': []}),
      throwsStateError,
    );
  });
  test('missing register is never initialized by a test run', () {
    final directory = Directory.systemTemp.createTempSync(
      'architecture register ',
    );
    try {
      final file = File('${directory.path}/legacy.json');
      expect(() => readLegacy(file), throwsStateError);
      expect(file.existsSync(), isFalse);
    } finally {
      directory.deleteSync(recursive: true);
    }
  });
}
