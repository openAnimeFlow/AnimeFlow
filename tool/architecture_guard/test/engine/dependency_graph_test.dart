@Tags(['architecture'])
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'package:anime_flow_architecture_guard/src/boundary_checks.dart';
import 'package:anime_flow_architecture_guard/src/dependency_graph.dart';
import 'package:anime_flow_architecture_guard/src/model.dart';

import 'fixture_project.dart';

void main() {
  late FixtureProject fixture;
  tearDown(() => fixture.dispose());
  test('unknown SDK URI in inactive branch fails closed', () {
    fixture = FixtureProject({
      'lib/core/bridge.dart':
          "import 'dart:math' if (dart.library.html) 'dart:missing_library';",
    });
    expect(
      () => collectDependencies(fixture.root, fixtureSpec()),
      throwsStateError,
    );
  });
  test('case-mismatched project import fails on every platform', () {
    fixture = FixtureProject({
      'lib/core/bridge.dart': "import 'VALUE.dart';",
      'lib/core/value.dart': 'class Value {}',
    });
    expect(
      () => collectDependencies(fixture.root, fixtureSpec()),
      throwsStateError,
    );
  });
  test('relative/package/file imports have the same canonical target', () {
    fixture = FixtureProject({
      'lib/features/a/application/one.dart': "import '../domain/value.dart';",
      'lib/features/a/application/two.dart':
          "import 'package:anime_flow/features/a/domain/value.dart';",
      'lib/features/a/domain/value.dart': 'class Value {}',
    });
    final uri = File(p.join(fixture.root, 'lib/features/a/domain/value.dart'))
        .uri;
    fixture.write('lib/features/a/application/three.dart', "import '$uri';");
    final graph = collectDependencies(fixture.root, fixtureSpec());
    expect(graph.edges.map((e) => e.target).toSet(), {
      'lib/features/a/domain/value.dart',
    });
    expect(graph.edges.length, 3);
    expect(findProjectRoot(p.join(fixture.root, 'lib')), fixture.root);
  });
  test('all conditional import and export branches are inspected', () {
    fixture = FixtureProject({
      'lib/core/bridge.dart': "import 'safe.dart' if (dart.library.io) '../features/a/domain/value.dart';\nexport 'safe.dart' if (dart.library.html) '../features/a/domain/value.dart';",
      'lib/core/safe.dart': 'class Safe {}',
      'lib/features/a/domain/value.dart': 'class Value {}',
    });
    final graph = collectDependencies(fixture.root, fixtureSpec());
    expect(graph.edges.length, 4);
    expect(
      checkBoundaries(
        graph,
        fixtureSpec(),
      ).where((v) => v.rule == 'R01').length,
      2,
    );
  });
  test('missing dependency in inactive conditional branch fails closed', () {
    fixture = FixtureProject({
      'lib/core/bridge.dart':
          "import 'safe.dart' if (dart.library.html) 'missing.dart';",
      'lib/core/safe.dart': '',
    });
    expect(
      () => collectDependencies(fixture.root, fixtureSpec()),
      throwsStateError,
    );
  });
  test('handwritten/generated parts belong to their declaring library', () {
    fixture = FixtureProject({
      'lib/features/a/domain/value.dart':
          "library value;\npart 'helper.dart';\npart 'value.g.dart';",
      'lib/features/a/domain/helper.dart': 'part of value;\nclass Helper {}',
      'lib/features/a/domain/value.g.dart':
          'part of value;\nclass Generated {}',
    });
    final graph = collectDependencies(fixture.root, fixtureSpec());
    expect(graph.libraries.length, 1);
    expect(graph.edges, isEmpty);
    expect(
      graph.units['lib/features/a/domain/value.g.dart']!.library,
      'lib/features/a/domain/value.dart',
    );
  });
  test('orphan part fails rather than disappearing from coverage', () {
    fixture = FixtureProject({
      'lib/features/a/domain/value.g.dart': 'part of missing;',
    });
    expect(
      () => collectDependencies(fixture.root, fixtureSpec()),
      throwsStateError,
    );
  });
  test('malformed source fails', () {
    fixture = FixtureProject({'lib/features/a/domain/value.dart': 'class {'});
    expect(
      () => collectDependencies(fixture.root, fixtureSpec()),
      throwsStateError,
    );
  });
  test('empty scan fails', () {
    fixture = FixtureProject({});
    Directory(p.join(fixture.root, 'lib')).createSync();
    expect(
      () => collectDependencies(fixture.root, fixtureSpec()),
      throwsStateError,
    );
  });
  test('missing package or escaped lib import fails', () {
    fixture = FixtureProject({
      'lib/core/value.dart': "import 'package:missing/value.dart';",
    });
    expect(
      () => collectDependencies(fixture.root, fixtureSpec()),
      throwsStateError,
    );
    fixture.write('lib/core/value.dart', "import '../../pubspec.yaml';");
    expect(
      () => collectDependencies(fixture.root, fixtureSpec()),
      throwsStateError,
    );
  });
  test('new undeclared feature fails coverage', () {
    fixture = FixtureProject({'lib/features/unknown/domain/value.dart': ''});
    expect(
      () => collectDependencies(fixture.root, fixtureSpec()),
      throwsStateError,
    );
  });
  test('duplicate responsibility and unmatched required scope fail', () {
    fixture = FixtureProject({'lib/core/value.dart': ''});
    final duplicate = ArchitectureSpec([
      ModuleSpec('core', 'lib/core', [
        SourceScope('lib/core/**', Responsibility.foundation),
        SourceScope('lib/core/**', Responsibility.ui),
      ]),
    ]);
    expect(
      () => collectDependencies(fixture.root, duplicate),
      throwsStateError,
    );
    final missing = ArchitectureSpec([
      ModuleSpec('core', 'lib/core', [
        SourceScope('lib/core/missing.dart', Responsibility.foundation),
      ]),
    ]);
    expect(() => collectDependencies(fixture.root, missing), throwsStateError);
  });
}
