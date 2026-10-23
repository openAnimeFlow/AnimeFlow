@Tags(['architecture'])
library;

import 'package:test/test.dart';
import 'package:anime_flow_architecture_guard/architecture_spec.dart';
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

  test(
    'UI providers and composition bindings have precise classifications',
    () {
      const ui =
          'lib/features/play/presentation/providers/video_ui_provider.dart';
      const source =
          'lib/features/play/presentation/providers/play_provider.dart';
      fixture = FixtureProject({
        ui: "import 'package:flutter/widgets.dart';",
        source: "import 'video_ui_provider.dart';",
        'lib/features/play/application/player_bindings.dart':
            "import '../presentation/providers/video_ui_provider.dart';",
      });
      final spec = fixtureSpec();
      final violations = checkBoundaries(
        collectDependencies(fixture.root, spec),
        spec,
      );
      expect(violations.single.source, source);
      expect(violations.single.target, ui);
      expect(
        projectArchitecture().roleOf(
          'lib/features/play/presentation/providers/new_provider.dart',
        ),
        Responsibility.business,
      );
      expect(ArchitectureSpec.rules, {'R03', 'R07'});
    },
  );
}
