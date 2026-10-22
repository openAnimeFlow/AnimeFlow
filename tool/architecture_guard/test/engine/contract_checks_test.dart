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
      'lib/features/a/presentation/widgets/dio.dart': "import 'package:dio/dio.dart';\nvoid request(Dio client) { client.get('/'); final send = client.post; send('/'); }",
      'lib/features/a/presentation/widgets/http.dart': "import 'package:http/http.dart' as http;\nvoid request(http.Client client) { client.send(http.Request('GET', Uri.parse('https://example.invalid'))); http.get(Uri.parse('https://example.invalid')); }",
      'lib/features/a/presentation/widgets/override.dart': "import 'package:dio/dio.dart';\nabstract class Transport implements Dio { @override Future<Response<T>> fetch<T>(RequestOptions options); }\nvoid request(Transport transport) { transport.fetch<int>(RequestOptions(path: '/')); }",
      'lib/features/a/presentation/widgets/io.dart': "import 'dart:io';\nvoid request(HttpClient client) { client.openUrl('GET', Uri.parse('https://example.invalid')); }",
      'lib/features/a/presentation/widgets/transport_types.dart': "import 'package:dio/dio.dart';\nclass Local { int get() => 1; }\nvoid cancel(CancelToken token) { token.cancel(); Local().get(); }",
      'lib/features/a/presentation/providers/dio.dart': "import 'package:dio/dio.dart';\nFuture<void> request(Dio client) async { await client.get('/'); }",
      'lib/features/b/api.dart': "export 'application/wrapper.dart' show create, commandsProvider, notifierProvider, inheritedProvider, safeProvider;\nexport 'package:flutter/widgets.dart' show Widget;",
      'lib/features/b/application/wrapper.dart':
          r'''import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository.dart';
Repository create() => Repository();
final commandsProvider = Provider((ref) => Commands());
class Commands { ProviderRepository get repository => ProviderRepository(); }
final notifierProvider = NotifierProvider<CommandsNotifier, int>(CommandsNotifier.new);
class CommandsNotifier extends Notifier<int> {
  @override
  int build() => 0;
  NotifierRepository get repository => NotifierRepository();
}
class Base<T> { T? get payload => null; }
class Derived extends Base<InheritedRepository> {}
// The entry type itself has no type arguments, like generated Provider classes.
final inheritedProvider = Derived();
final safeProvider = Provider((ref) => SafeCommands());
class SafeCommands {
  final PrivateRepository _repository = PrivateRepository();
  int get value => _repository.hashCode;
  Node<int> get tree => Node<int>();
}
class Node<T> { Node<List<T>> get next => Node<List<T>>(); }
''',
      'lib/features/b/data/repository.dart': 'class Repository {}\nclass ProviderRepository {}\nclass NotifierRepository {}\nclass InheritedRepository {}\nclass PrivateRepository {}',
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
  test('UI rejects Dio, http and HttpClient calls/tear-offs, but permits cancellation types', () {
    for (final name in ['dio', 'http', 'io', 'override']) {
      expect(
        violations.where(
          (v) => v.source.endsWith('widgets/$name.dart') && v.rule == 'R04',
        ),
        isNotEmpty,
        reason: name,
      );
    }
    expect(
      violations.where(
        (v) =>
            v.source.endsWith('widgets/transport_types.dart') ||
            v.source.endsWith('providers/dio.dart'),
      ),
      isEmpty,
    );
  });
  test('public Provider values, notifiers and instantiated inherited members cannot leak implementations', () {
    final found = violations.where(
      (v) => v.source == 'lib/features/b/api.dart' && v.rule == 'R06',
    );
    for (final name in [
      'ProviderRepository',
      'NotifierRepository',
      'InheritedRepository',
    ]) {
      expect(
        found.where((v) => v.target.endsWith('#$name')),
        isNotEmpty,
        reason: name,
      );
    }
    expect(
      found.where((v) => v.target.endsWith('#PrivateRepository')),
      isEmpty,
    );
  });
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
