// 验收循环的图结构；全量门禁检查项目中的真实依赖。
@Tags(['architecture'])
library;

import 'package:test/test.dart';

import 'package:anime_flow_architecture_guard/src/cycle_checks.dart';
import 'package:anime_flow_architecture_guard/src/dependency_graph.dart';

import 'fixture_project.dart';

void main() {
  late FixtureProject fixture;
  tearDown(() => fixture.dispose());
  test('feature cycles without file cycles are still rejected', () {
    fixture = FixtureProject({
      'lib/features/a/application/one.dart':
          "import '../../b/application/two.dart';",
      'lib/features/b/application/two.dart': '',
      'lib/features/b/application/three.dart':
          "import '../../a/application/four.dart';",
      'lib/features/a/application/four.dart': '',
    });
    final spec = fixtureSpec();
    expect(
      checkCycles(collectDependencies(fixture.root, spec), spec).length,
      2,
    );
  });
  test('three-file cycle and new edge inside existing SCC are identified individually', () {
    fixture = FixtureProject({
      'lib/core/a.dart': "import 'b.dart';",
      'lib/core/b.dart': "import 'c.dart';",
      'lib/core/c.dart': "import 'a.dart';",
    });
    final spec = fixtureSpec();
    final original = checkCycles(
      collectDependencies(fixture.root, spec),
      spec,
    ).map((v) => v.key).toSet();
    expect(original.length, 3);
    fixture.write('lib/core/a.dart', "import 'b.dart';\nimport 'c.dart';");
    final expanded = checkCycles(
      collectDependencies(fixture.root, spec),
      spec,
    ).map((v) => v.key).toSet();
    expect(
      expanded.difference(original).single,
      contains('lib/core/a.dart|lib/core/c.dart'),
    );
  });
  test('acyclic and part relationships do not create cycles', () {
    fixture = FixtureProject({
      'lib/core/a.dart': "import 'b.dart';\npart 'a.g.dart';",
      'lib/core/a.g.dart': "part of 'a.dart';",
      'lib/core/b.dart': '',
    });
    expect(
      checkCycles(
        collectDependencies(fixture.root, fixtureSpec()),
        fixtureSpec(),
      ),
      isEmpty,
    );
  });
  test(
    'exact generated group suppresses only its internal generated cycle',
    () {
      fixture = FixtureProject({
        'lib/core/generated.dart':
            "import 'generated_en.dart';\nimport 'business.dart';",
        'lib/core/generated_en.dart': "import 'generated.dart';",
        'lib/core/business.dart': "import 'generated.dart';",
      });
      final spec = fixtureSpec(
        generatedGroups: {
          'localizations': {
            'lib/core/generated.dart',
            'lib/core/generated_en.dart',
          },
        },
      );
      final violations = checkCycles(
        collectDependencies(fixture.root, spec),
        spec,
      );
      expect(violations.length, 2);
      expect(
        violations.every(
          (v) => v.source.contains('business') || v.target.contains('business'),
        ),
        isTrue,
      );
    },
  );
  test('self imports in unclassified files remain cycles', () {
    fixture = FixtureProject({'lib/custom/value.dart': "import 'value.dart';"});
    final spec = fixtureSpec();
    final violation = checkCycles(
      collectDependencies(fixture.root, spec),
      spec,
    ).single;
    expect(violation.source, 'lib/custom/value.dart');
    expect(violation.target, violation.source);
  });

  test('conditional exports participate in cycles on every platform', () {
    fixture = FixtureProject({
      'lib/custom/a.dart':
          "export 'safe.dart' if (dart.library.html) 'b.dart';",
      'lib/custom/safe.dart': '',
      'lib/custom/b.dart': "import 'a.dart';",
    });
    final spec = fixtureSpec();
    final violations = checkCycles(
      collectDependencies(fixture.root, spec),
      spec,
    );
    expect(violations, hasLength(2));
    expect(
      violations.map((violation) => violation.kind),
      containsAll(['import', 'export']),
    );
  });
  test('a file directly under features is not treated as a feature module', () {
    fixture = FixtureProject({
      'lib/features/registry.dart': "export 'new_feature/domain/value.dart';",
      'lib/features/new_feature/domain/value.dart': '',
    });
    final spec = fixtureSpec();
    expect(checkCycles(collectDependencies(fixture.root, spec), spec), isEmpty);
  });
}
