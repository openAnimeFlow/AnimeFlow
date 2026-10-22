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
    for (final file in suites) {
      expect(
          file.readAsStringSync().startsWith("@Tags(['architecture'])"), isTrue,
          reason:
              'Acceptance suite must be selected by the CI architecture tag: ${file.path}');
    }
    await run([
      'test',
      '--reporter',
      'expanded',
      '--concurrency=1',
      '--tags',
      'architecture'
    ]);
  }, timeout: const Timeout(Duration(minutes: 8)));
  test('complete source graph obeys the architecture specification', () async {
    await run([
      '--packages=${p.join(tool, '.dart_tool', 'package_config.json')}',
      p.join(tool, 'bin', 'check.dart'),
      root
    ]);
  }, timeout: const Timeout(Duration(minutes: 8)));
}
