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

  for (final layer in ['application', 'domain', 'presentation/providers']) {
    test('$layer cannot import UI from another feature', () {
      const target = 'lib/features/b/presentation/widgets/page.dart';
      final source = 'lib/features/new_feature/$layer/service.dart';
      fixture = FixtureProject({
        source: "import 'package:anime_flow/features/b/presentation/widgets/page.dart';",
        target: '',
      });
      final spec = fixtureSpec();
      final violation = checkBoundaries(
        collectDependencies(fixture.root, spec),
        spec,
      ).single;
      expect(violation.rule, 'R03');
      expect(violation.source, source);
      expect(violation.target, target);
    });
  }

  test(
    'UI cannot be hidden behind cyclic re-exports or conditional branches',
    () {
      const source = 'lib/features/a/application/service.dart';
      const ui = 'lib/shared/widgets/toast.dart';
      fixture = FixtureProject({
        source: "import '../../../core/barrel.dart' show Value;",
        'lib/core/barrel.dart': "export 'other.dart';",
        'lib/core/other.dart': "export 'barrel.dart';\nexport 'safe.dart' if (dart.library.io) '../shared/widgets/toast.dart' hide Unused;",
        'lib/core/safe.dart': '',
        ui: '',
      });
      final spec = fixtureSpec();
      final violation = checkBoundaries(
        collectDependencies(fixture.root, spec),
        spec,
      ).single;
      expect(violation.source, source);
      expect(violation.target, ui);
    },
  );

  test('business cannot re-export UI', () {
    fixture = FixtureProject({
      'lib/features/a/application/service.dart':
          "export '../presentation/pages/page.dart';",
      'lib/features/a/presentation/pages/page.dart': '',
    });
    final spec = fixtureSpec();
    expect(
      checkBoundaries(
        collectDependencies(fixture.root, spec),
        spec,
      ).single.kind,
      'export',
    );
  });

  test('business cannot acquire UI navigation through its provider', () {
    const source = 'lib/features/auth/application/service.dart';
    const target = 'lib/shared/navigation/app_navigator_provider.dart';
    fixture = FixtureProject({
      source: "import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';",
      target: '',
    });
    final spec = fixtureSpec();
    final violation = checkBoundaries(
      collectDependencies(fixture.root, spec),
      spec,
    ).single;
    expect(violation.rule, 'R03');
    expect(violation.source, source);
    expect(violation.target, target);
  });

  test('framework UI imports are rejected but foundation and Riverpod remain allowed', () {
    const source = 'lib/features/a/application/service.dart';
    fixture = FixtureProject({
      source: "import 'package:flutter/foundation.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';",
    });
    final spec = fixtureSpec();
    expect(
      checkBoundaries(collectDependencies(fixture.root, spec), spec),
      isEmpty,
    );
    for (final uri in [
      'package:flutter/widgets.dart',
      'package:flutter/material.dart',
      'package:cupertino_ui/cupertino_ui.dart',
      'package:cupertino_ui/src/button.dart',
      'dart:ui',
    ]) {
      fixture.write(source, "import '$uri';");
      expect(
        checkBoundaries(
          collectDependencies(fixture.root, spec),
          spec,
        ).single.target,
        uri,
      );
    }
  });

  test('business cannot import Cupertino UI through a local re-export', () {
    const source = 'lib/features/a/application/service.dart';
    const ui = 'package:cupertino_ui/cupertino_ui.dart';
    fixture = FixtureProject({
      source: "import '../../../core/barrel.dart';",
      'lib/core/barrel.dart': "export '$ui';",
      'lib/features/a/presentation/widgets/page.dart': "import '$ui';",
    });
    final spec = fixtureSpec();
    final violation = checkBoundaries(
      collectDependencies(fixture.root, spec),
      spec,
    ).single;
    expect(violation.rule, 'R03');
    expect(violation.source, source);
    expect(violation.target, ui);
  });

  test('business providers may depend on other business providers and concrete APIs', () {
    fixture = FixtureProject({
      'lib/features/a/application/service.dart': "import '../../b/presentation/providers/query.dart';\nimport '../data/repository.dart';\nimport '../../../core/network/api/value.dart';",
      'lib/features/b/presentation/providers/query.dart': '',
      'lib/features/a/data/repository.dart': '',
      'lib/core/network/api/value.dart': '',
      'lib/features/a/domain/value.dart': "import 'package:dio/dio.dart';",
    });
    final spec = fixtureSpec();
    expect(
      checkBoundaries(collectDependencies(fixture.root, spec), spec),
      isEmpty,
    );
  });

  test(
    'UI files and other layers may use UI without business restrictions',
    () {
      fixture = FixtureProject({
        'lib/features/a/presentation/widgets/page.dart':
            "import 'package:flutter/widgets.dart';",
        'lib/features/a/data/value.dart':
            "import 'package:flutter/widgets.dart';",
        'lib/core/value.dart': "import 'package:flutter/widgets.dart';",
      });
      final spec = fixtureSpec();
      expect(
        checkBoundaries(collectDependencies(fixture.root, spec), spec),
        isEmpty,
      );
    },
  );

  test('download domain excludes storage through local helpers', () {
    const domain = 'lib/features/download/domain';
    fixture = FixtureProject({
      '$domain/record.dart': "import 'value.dart';",
      '$domain/value.dart': "import 'package:hive_ce/hive.dart';",
      '$domain/status.dart': 'class Status {}',
    });
    final spec = fixtureSpec();
    final hits = checkBoundaries(collectDependencies(fixture.root, spec), spec)
        .where((violation) => violation.rule == 'R11')
        .map((violation) => (violation.source, violation.target))
        .toSet();
    expect(hits, {
      ('$domain/record.dart', 'package:hive_ce/hive.dart'),
      ('$domain/value.dart', 'package:hive_ce/hive.dart'),
    });
  });

  test(
    'play enforces inward dependencies through local helpers and barrels',
    () {
      const root = 'lib/features/play';
      fixture = FixtureProject({
        '$root/application/session.dart': "import '../../../core/helper.dart';",
        'lib/core/helper.dart': "import 'dart:io';",
        '$root/domain/model.dart': "import '../application/session.dart';",
        '$root/presentation/providers/page.dart':
            "import '../../../shared/barrel.dart';",
        'lib/features/shared/barrel.dart':
            "export '../play/infrastructure/store.dart';",
        '$root/infrastructure/store.dart': "import '../domain/contract.dart';",
        '$root/domain/contract.dart': "import 'dart:async';",
        '$root/infrastructure/bad.dart':
            "import '../presentation/providers/page.dart';",
      });
      final spec = fixtureSpec();
      final hits = checkBoundaries(
        collectDependencies(fixture.root, spec),
        spec,
      ).where((v) => v.rule == 'R11').map((v) => (v.source, v.target)).toSet();
      expect(
        hits,
        containsAll([
          ('$root/application/session.dart', 'dart:io'),
          ('$root/domain/model.dart', '$root/application/session.dart'),
          (
            '$root/presentation/providers/page.dart',
            '$root/infrastructure/store.dart',
          ),
          (
            '$root/infrastructure/bad.dart',
            '$root/presentation/providers/page.dart',
          ),
        ]),
      );
      expect(
        hits.any((edge) => edge.$1 == '$root/infrastructure/store.dart'),
        isFalse,
      );
      expect(
        spec.roleOf('$root/presentation/providers/page.dart'),
        Responsibility.ui,
      );
    },
  );

  test('features and shared widgets cannot import application routes', () {
    const route = 'lib/app/router/app_router.dart';
    fixture = FixtureProject({
      route: '',
      'lib/features/search/presentation/pages/page.dart':
          "import '../../../../app/router/app_router.dart';",
      'lib/shared/widgets/link.dart':
          "import 'package:anime_flow/app/router/app_router.dart';",
    });
    final spec = fixtureSpec();
    final violations = checkBoundaries(
      collectDependencies(fixture.root, spec),
      spec,
    );
    expect(violations, hasLength(2));
    expect(
      violations.every((v) => v.rule == 'R10' && v.target == route),
      isTrue,
    );
  });

  test('route boundary follows conditional and cyclic re-exports', () {
    const route = 'lib/app/router/app_router.dart';
    const source = 'lib/features/search/presentation/pages/page.dart';
    fixture = FixtureProject({
      source: "import '../../../../core/facade.dart' show Destination;",
      'lib/core/facade.dart': "export 'other.dart';",
      'lib/core/other.dart': "export 'facade.dart';\nexport 'safe.dart' if (dart.library.io) '../app/router/app_router.dart';",
      'lib/core/safe.dart': '',
      route: '',
    });
    final spec = fixtureSpec();
    final violation = checkBoundaries(
      collectDependencies(fixture.root, spec),
      spec,
    ).single;
    expect(violation.rule, 'R10');
    expect(violation.source, source);
    expect(violation.target, route);
  });

  test('navigation contracts cannot import feature implementations', () {
    const source = 'lib/shared/navigation/app_navigator.dart';
    const page = 'lib/features/search/presentation/pages/page.dart';
    fixture = FixtureProject({
      source: "import '../../features/search/presentation/pages/page.dart';",
      page: '',
    });
    final spec = fixtureSpec();
    expect(
      checkBoundaries(
        collectDependencies(fixture.root, spec),
        spec,
      ).single.rule,
      'R10',
    );
  });

  test('app composes pages while pages depend on navigation contracts', () {
    fixture = FixtureProject({
      'lib/app/router/app_router.dart':
          "import '../../features/search/presentation/pages/page.dart';",
      'lib/app/router/go_app_navigator.dart': "import '../../shared/navigation/app_navigator.dart';\nimport 'app_router.dart';",
      'lib/features/search/presentation/pages/page.dart':
          "import '../../../../shared/navigation/app_navigator.dart';",
      'lib/shared/navigation/app_navigator.dart':
          "import 'package:flutter/widgets.dart';",
    });
    final spec = fixtureSpec();
    expect(
      checkBoundaries(collectDependencies(fixture.root, spec), spec),
      isEmpty,
    );
  });
}
