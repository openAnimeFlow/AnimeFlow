@Tags(['architecture'])
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'package:anime_flow_architecture_guard/src/contract_checks.dart';
import 'package:anime_flow_architecture_guard/src/dependency_graph.dart';
import 'package:anime_flow_architecture_guard/src/model.dart';

import 'fixture_project.dart';

void main() {
  late FixtureProject fixture;
  late List<ArchitectureViolation> violations;
  String template(String path) =>
      File(p.join(findProjectRoot(), 'test/architecture/fixtures', path))
          .readAsStringSync();
  setUpAll(() async {
    fixture = FixtureProject({
      'lib/core/network/api/value.dart':
          'class ValueApi { static int load() => 1; }',
      'lib/features/a/presentation/providers/value.dart': template(
        'valid_project/provider.dart.txt',
      ),
      'lib/features/a/application/widget.dart': template(
        'business_widget_usage/business.dart.txt',
      ),
      'lib/features/a/application/custom.dart':
          'class Widget {}\nWidget load() => Widget();',
      'lib/features/a/application/ref.dart': "import 'package:flutter_riverpod/flutter_riverpod.dart';\nint value(Ref ref) => 1;\nAsyncValue<int> result() => const AsyncData(1);",
      'lib/features/a/application/widget_ref.dart': "import 'package:flutter_riverpod/flutter_riverpod.dart';\nvoid use(WidgetRef ref) {}",
      'lib/features/a/presentation/providers/widget.dart': "import 'package:flutter/widgets.dart';\nWidget load() => const Text('wrong');",
      'lib/features/a/presentation/widgets/view.dart': "import 'package:flutter/widgets.dart';\nWidget buildView() => const Text('allowed UI');",
      'lib/features/a/presentation/widgets/api.dart': "import 'package:anime_flow/core/network/api/value.dart' as api;\nint load() => api.ValueApi.load();",
      'lib/features/b/api.dart': "export 'application/wrapper.dart' show create;\nexport 'package:flutter/widgets.dart' show Widget;",
      'lib/features/b/application/wrapper.dart': "import '../data/repository.dart';\nRepository create() => Repository();",
      'lib/features/b/data/repository.dart': 'class Repository {}',
    });
    final spec = fixtureSpec(publicB: {'lib/features/b/api.dart'});
    violations = await checkContracts(
      collectDependencies(fixture.root, spec),
      spec,
    );
  });
  tearDownAll(() => fixture.dispose());
  test(
    'public entry cannot re-export Widget without a local type annotation',
    () {
      expect(
        violations.where(
          (v) =>
              v.source == 'lib/features/b/api.dart' &&
              v.rule == 'R09' &&
              v.target.endsWith('#Widget'),
        ),
        isNotEmpty,
      );
    },
  );
  test('business signatures, aliases, generics and method bodies cannot use widgets', () {
    final found = violations
        .where((v) => v.source.endsWith('application/widget.dart'))
        .toList();
    expect(
      found.where((v) => v.rule == 'R09' && v.target.endsWith('#Widget')),
      isNotEmpty,
    );
    expect(
      found.where((v) => v.rule == 'R09' && v.target.endsWith('#BuildContext')),
      isNotEmpty,
    );
  });
  test('simple business Provider may call API but cannot return Widget', () {
    expect(
      violations.where((v) => v.source.endsWith('providers/value.dart')),
      isEmpty,
    );
    expect(
      violations.where(
        (v) => v.source.endsWith('providers/widget.dart') && v.rule == 'R09',
      ),
      isNotEmpty,
    );
  });
  test(
    'legitimate Ref/AsyncValue and unrelated custom Widget type are allowed',
    () {
      expect(
        violations.where(
          (v) =>
              v.source.endsWith('application/ref.dart') ||
              v.source.endsWith('application/custom.dart'),
        ),
        isEmpty,
      );
      expect(
        violations.where(
          (v) =>
              v.source.endsWith('application/widget_ref.dart') &&
              v.rule == 'R09',
        ),
        isNotEmpty,
      );
    },
  );
  test('presentation builds Widgets but accesses API through a Provider', () {
    expect(
      violations.where((v) => v.source.endsWith('widgets/view.dart')),
      isEmpty,
    );
    expect(
      violations.where(
        (v) => v.source.endsWith('widgets/api.dart') && v.rule == 'R04',
      ),
      isNotEmpty,
    );
  });
  test(
    'public entry cannot leak implementation through a function return type',
    () {
      expect(
        violations.where(
          (v) => v.source == 'lib/features/b/api.dart' && v.rule == 'R06',
        ),
        isNotEmpty,
      );
    },
  );
  test(
    'semantic errors fail instead of returning an empty success report',
    () async {
      final broken = FixtureProject({
        'lib/features/a/application/broken.dart':
            'final value = unknownSymbol;',
      });
      try {
        final spec = fixtureSpec();
        await expectLater(
          checkContracts(collectDependencies(broken.root, spec), spec),
          throwsStateError,
        );
      } finally {
        broken.dispose();
      }
    },
  );
}
