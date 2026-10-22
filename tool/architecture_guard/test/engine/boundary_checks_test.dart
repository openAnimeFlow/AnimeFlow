@Tags(['architecture'])
library;

import 'package:test/test.dart';

import 'package:anime_flow_architecture_guard/src/boundary_checks.dart';
import 'package:anime_flow_architecture_guard/src/dependency_graph.dart';
import 'package:anime_flow_architecture_guard/src/model.dart';

import 'fixture_project.dart';

void main() {
  late FixtureProject fixture;
  tearDown(() => fixture.dispose());
  test('core cannot reach feature through barrel show/hide exports', () {
    fixture = FixtureProject({
      'lib/core/client.dart': "import 'barrel.dart' show Value;",
      'lib/core/barrel.dart':
          "export '../features/a/domain/value.dart' hide Other;",
      'lib/features/a/domain/value.dart': 'class Value {}',
    });
    final graph = collectDependencies(fixture.root, fixtureSpec());
    expect(
      checkBoundaries(
        graph,
        fixtureSpec(),
      ).where((v) => v.rule == 'R01').map((v) => v.source).toSet(),
      {'lib/core/client.dart', 'lib/core/barrel.dart'},
    );
  });
  test('data cannot depend on UI or business state', () {
    fixture = FixtureProject({
      'lib/features/a/data/repository.dart': "import '../presentation/widgets/page.dart';\nimport '../application/state.dart';",
      'lib/features/a/presentation/widgets/page.dart': '',
      'lib/features/a/application/state.dart': '',
    });
    final graph = collectDependencies(fixture.root, fixtureSpec());
    expect(
      checkBoundaries(
        graph,
        fixtureSpec(),
      ).where((v) => v.rule == 'R02').length,
      2,
    );
  });
  test('application cannot reverse-import presentation', () {
    fixture = FixtureProject({
      'lib/features/a/application/service.dart':
          "import '../presentation/widgets/page.dart';",
      'lib/features/a/presentation/widgets/page.dart': '',
    });
    final graph = collectDependencies(fixture.root, fixtureSpec());
    expect(
      checkBoundaries(graph, fixtureSpec()).map((v) => v.rule),
      contains('R03'),
    );
  });
  test(
    'simple Provider may call API and use CancelToken without legacy debt',
    () {
      fixture = FixtureProject({
        'lib/features/a/presentation/providers/state.dart': "import 'package:dio/dio.dart';\nimport '../../../../core/network/api/value.dart';",
        'lib/core/network/api/value.dart': 'int load() => 1;',
      });
      final graph = collectDependencies(fixture.root, fixtureSpec());
      expect(checkBoundaries(graph, fixtureSpec()), isEmpty);
      expect(
        checkBoundaries(
          graph,
          fixtureSpec(mode: AccessMode.repository),
        ).map((v) => v.rule),
        contains('R04'),
      );
    },
  );
  test('public business entry is allowed; direct implementation import is rejected', () {
    fixture = FixtureProject({
      'lib/features/a/application/service.dart':
          "import 'package:anime_flow/features/b/api.dart';",
      'lib/features/b/api.dart': "export 'application/state.dart';",
      'lib/features/b/application/state.dart': 'class State {}',
    });
    final spec = fixtureSpec(publicB: {'lib/features/b/api.dart'});
    expect(
      checkBoundaries(collectDependencies(fixture.root, spec), spec),
      isEmpty,
    );
    fixture.write(
      'lib/features/a/application/service.dart',
      "import 'package:anime_flow/features/b/application/state.dart';",
    );
    expect(
      checkBoundaries(
        collectDependencies(fixture.root, spec),
        spec,
      ).map((v) => v.rule),
      contains('R06'),
    );
  });
  test('public entry cannot export implementation through a wrapper', () {
    fixture = FixtureProject({
      'lib/features/b/api.dart': "export 'application/barrel.dart';",
      'lib/features/b/application/barrel.dart':
          "export '../data/repository.dart' show Repository;",
      'lib/features/b/data/repository.dart': 'class Repository {}',
    });
    final spec = fixtureSpec(publicB: {'lib/features/b/api.dart'});
    expect(
      checkBoundaries(
        collectDependencies(fixture.root, spec),
        spec,
      ).where((v) => v.rule == 'R06'),
      isNotEmpty,
    );
  });
  test('domain cannot depend on Flutter or concrete settings via exports', () {
    fixture = FixtureProject({
      'lib/features/a/domain/value.dart': "import '../../../core/bridge.dart';",
      'lib/core/bridge.dart': "export 'package:flutter/widgets.dart';",
    });
    expect(
      checkBoundaries(
        collectDependencies(fixture.root, fixtureSpec()),
        fixtureSpec(),
      ).map((v) => v.rule),
      contains('R05'),
    );
  });
}
