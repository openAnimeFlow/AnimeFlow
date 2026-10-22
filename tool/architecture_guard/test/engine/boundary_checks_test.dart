@Tags(['architecture'])
library;

import 'package:test/test.dart';

import 'package:anime_flow_architecture_guard/src/boundary_checks.dart';
import 'package:anime_flow_architecture_guard/src/dependency_graph.dart';
import 'package:anime_flow_architecture_guard/src/model.dart';
import 'package:anime_flow_architecture_guard/architecture_spec.dart';

import 'fixture_project.dart';

void main() {
  late FixtureProject fixture;
  tearDown(() => fixture.dispose());
  test('pure business ports reject platform leaks transitively without reversing domain dependencies', () {
    const coordinator = 'lib/features/a/application/coordinator.dart';
    const port = 'lib/features/a/application/port.dart';
    const engine = 'lib/features/a/domain/engine.dart';
    const queue = 'lib/core/queue.dart';
    const model = 'lib/shared/models/value.dart';
    fixture = FixtureProject({
      coordinator: "import 'port.dart';\nimport '../domain/engine.dart';\nimport '../../../core/queue.dart';",
      port: "import '../domain/engine.dart';\nimport '../../../shared/models/value.dart';",
      engine: 'abstract class Engine {}',
      queue: "import 'dart:async';",
      model: 'class Value {}',
      'lib/features/a/presentation/widgets/render.dart': '',
    });
    final modules = [
      ...fixtureSpec().modules,
      ModuleSpec('shared_models', 'lib/shared/models', [
        SourceScope('lib/shared/models/**.dart', Responsibility.model),
      ]),
    ];
    final spec = ArchitectureSpec(
      modules,
      pureBusiness: {coordinator, port, model},
      domainCoreTypes: {queue},
    );
    expect(
      checkBoundaries(collectDependencies(fixture.root, spec), spec),
      isEmpty,
    );
    fixture.write(model, "import 'package:flutter/widgets.dart';");
    fixture.write(engine, "import '../application/port.dart';");
    final violations = checkBoundaries(
      collectDependencies(fixture.root, spec),
      spec,
    );
    expect(
      violations.where((v) => v.rule == 'R05').map((v) => v.source).toSet(),
      {coordinator, port, model, engine},
    );
    for (final invalid in [
      'lib/missing.dart',
      'lib/features/a/presentation/widgets/render.dart',
    ]) {
      expect(
        () => ArchitectureSpec(modules, pureBusiness: {invalid}).validate({
          coordinator,
          port,
          engine,
          queue,
          model,
          'lib/features/a/presentation/widgets/render.dart',
        }),
        throwsStateError,
      );
    }
  });
  test('shared video resolution keeps contracts pure and implementation selection in composition', () {
    const service =
        'lib/core/video_source/infrastructure/webview_video_source_service.dart';
    const factory =
        'lib/core/webview/video/video_webview_controller_factory.dart';
    const contract = 'lib/core/video_source/domain/video_source.dart';
    const providers = 'lib/core/video_source/application/providers.dart';
    const consumer = 'lib/features/a/application/resolve.dart';
    final project = projectArchitecture();
    final spec = ArchitectureSpec(
      [
        project.modules.singleWhere((module) => module.name == 'core'),
        ModuleSpec('app', 'lib/app', [
          SourceScope('lib/app/**.dart', Responsibility.composition),
        ]),
        ModuleSpec('a', 'lib/features/a', [
          SourceScope('lib/features/a/**.dart', Responsibility.business),
        ]),
      ],
      compositionOnly: project.compositionOnly
          .where((p) => p.startsWith('lib/core/'))
          .toSet(),
    );
    fixture = FixtureProject({
      'lib/app/setup.dart': "import '../core/video_source/infrastructure/webview_video_source_service.dart';\nimport '../core/webview/video/video_webview_controller_factory.dart';",
      'lib/core/webview/video/base.dart': 'abstract class NativeController {}',
      service: "import '../domain/video_source.dart';",
      factory: "import 'base.dart';",
      contract: 'abstract class VideoResolver {}',
      providers: "import '../domain/video_source.dart';",
      consumer: "import '../../../core/video_source/domain/video_source.dart';\nimport '../../../core/video_source/application/providers.dart';",
    });
    expect(
      checkBoundaries(collectDependencies(fixture.root, spec), spec),
      isEmpty,
    );
    fixture.write(
      'lib/core/resolver_barrel.dart',
      "export 'video_source/infrastructure/webview_video_source_service.dart';",
    );
    fixture.write(
      consumer,
      "import '../../../core/resolver_barrel.dart';\nimport '../../../core/webview/video/video_webview_controller_factory.dart';",
    );
    fixture.write(contract, "import '../application/providers.dart';");
    fixture.write(service, "import '../application/providers.dart';");
    final violations = checkBoundaries(
      collectDependencies(fixture.root, spec),
      spec,
    );
    expect(
      violations
          .where((v) => v.source == consumer && v.rule == 'R04')
          .map((v) => v.target)
          .toSet(),
      {service, factory},
    );
    expect(
      violations.where((v) => v.source == contract).map((v) => v.rule),
      contains('R05'),
    );
    expect(
      violations.where((v) => v.source == service).map((v) => v.rule),
      contains('R02'),
    );
  });
  test(
    'reusable UI entries allow UI consumers but reject business consumers',
    () {
      const entry = 'lib/features/b/presentation/widgets/login.dart';
      fixture = FixtureProject({
        entry: '',
        'lib/features/a/presentation/widgets/page.dart': "import 'package:anime_flow/features/b/presentation/widgets/login.dart';",
        'lib/features/a/application/login.dart': "import 'package:anime_flow/features/b/presentation/widgets/login.dart';",
      });
      final spec = fixtureSpec(uiB: {entry});
      final values = checkBoundaries(
        collectDependencies(fixture.root, spec),
        spec,
      );
      expect(
        values.where((v) => v.source.contains('/widgets/page.dart')),
        isEmpty,
      );
      expect(
        values.where((v) => v.rule == 'R06').single.source,
        'lib/features/a/application/login.dart',
      );
      expect(values.map((v) => v.rule), contains('R03'));
    },
  );
  test(
    'data may use a public signal export but signals cannot import business',
    () {
      const entry = 'lib/features/b/api.dart';
      const signal = 'lib/features/b/application/signal.dart';
      fixture = FixtureProject({
        'lib/features/a/data/cache.dart':
            "import 'package:anime_flow/features/b/api.dart';",
        entry: "export 'application/signal.dart';",
        signal: 'int revision = 0;',
        'lib/features/b/application/service.dart': 'void run() {}',
      });
      final spec = ArchitectureSpec(
        fixtureSpec(publicB: {entry}).modules,
        dataContracts: {entry: 'Public signal', signal: 'Pure signal'},
      );
      expect(
        checkBoundaries(collectDependencies(fixture.root, spec), spec),
        isEmpty,
      );
      fixture.write(signal, "import 'service.dart';");
      expect(
        checkBoundaries(
          collectDependencies(fixture.root, spec),
          spec,
        ).map((v) => v.rule),
        contains('R02'),
      );
    },
  );
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
