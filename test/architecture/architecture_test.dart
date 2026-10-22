@Tags(['architecture'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final root = Directory.current.path;
  final tool = p.join(root, 'tool', 'architecture_guard');
  final config = File(p.join(root, '.dart_tool', 'package_config.json'));
  final packages =
      (jsonDecode(config.readAsStringSync()) as Map)['packages'] as List;
  final flutter =
      packages.cast<Map>().singleWhere((entry) => entry['name'] == 'flutter');
  final uri = config.absolute.uri.resolve('${flutter['rootUri']}/');
  final dart = p.normalize(p.join(p.fromUri(uri), '..', '..', 'bin', 'cache',
      'dart-sdk', 'bin', Platform.isWindows ? 'dart.exe' : 'dart'));

  Future<void> run(List<String> arguments) async {
    expect(File(p.join(tool, '.dart_tool', 'package_config.json')).existsSync(),
        isTrue,
        reason:
            'Run dart pub get --enforce-lockfile in tool/architecture_guard first.');
    final result = await Process.run(dart, arguments, workingDirectory: tool);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    expect(result.exitCode, 0,
        reason: 'Architecture guard failed; see output above.');
  }

  test('architecture guard positive and negative acceptance cases', () async {
    const expectedSuites = {
      'boundary_checks_test.dart',
      'contract_checks_test.dart',
      'cycle_checks_test.dart',
      'dependency_graph_test.dart',
      'legacy_checks_test.dart',
      'workflow_checks_test.dart',
    };
    final suites = Directory(p.join(tool, 'test', 'engine'))
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('_test.dart'))
        .toList();
    expect(suites.map((file) => p.basename(file.path)).toSet(), expectedSuites,
        reason:
            'Acceptance suite inventory changed; review the inventory with the test changes.');
    final report =
        File(p.join(root, 'build', 'architecture', 'engine-tests.json'));
    report.parent.createSync(recursive: true);
    if (report.existsSync()) report.deleteSync();
    await run([
      'test',
      '--reporter',
      'expanded',
      '--concurrency=1',
      '--file-reporter',
      'json:${p.relative(report.path, from: tool)}',
      '--tags',
      'architecture'
    ]);
    final suiteNames = <int, String>{};
    final testSuites = <int, int>{};
    final executedSuites = <int>{};
    for (final line
        in report.readAsLinesSync().where((line) => line.isNotEmpty)) {
      final event = jsonDecode(line) as Map<String, dynamic>;
      if (event['type'] == 'suite') {
        final suite = event['suite'] as Map;
        suiteNames[suite['id'] as int] = p.basename(suite['path'] as String);
      } else if (event['type'] == 'testStart') {
        final test = event['test'] as Map;
        testSuites[test['id'] as int] = test['suiteID'] as int;
      } else if (event['type'] == 'testDone' &&
          event['hidden'] == false &&
          event['skipped'] == false &&
          event['result'] == 'success') {
        executedSuites.add(testSuites[event['testID']]!);
      }
    }
    expect(executedSuites.map((id) => suiteNames[id]).toSet(), expectedSuites,
        reason:
            'Every acceptance suite must actually run non-skipped tests under the architecture tag.');

    // The inverse selector must collect nothing, including partially untagged suites.
    final excluded = await Process.run(
        dart,
        [
          'test',
          '--reporter',
          'json',
          '--exclude-tags',
          'architecture',
        ],
        workingDirectory: tool);
    final events = const LineSplitter()
        .convert(excluded.stdout as String)
        .where((line) => line.isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final diagnostic = '${excluded.stdout}\n${excluded.stderr}';
    expect(
        events.where((event) => event['type'] == 'allSuites').single['count'],
        0,
        reason:
            'Untagged architecture tests would escape the CI selector.\n$diagnostic');
    expect(events.where((event) => event['type'] == 'done').single['success'],
        isTrue,
        reason:
            'An empty selection must not hide a runner failure.\n$diagnostic');
    expect(excluded.exitCode, isNot(0),
        reason:
            'Expected the test runner to report no tests selected.\n$diagnostic');
  }, timeout: const Timeout(Duration(minutes: 8)));
  test('complete source graph obeys the architecture specification', () async {
    await run([
      '--packages=${p.join(tool, '.dart_tool', 'package_config.json')}',
      p.join(tool, 'bin', 'check.dart'),
      root
    ]);
  }, timeout: const Timeout(Duration(minutes: 8)));
}
