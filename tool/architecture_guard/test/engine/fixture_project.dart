import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:anime_flow_architecture_guard/src/dependency_graph.dart';
import 'package:anime_flow_architecture_guard/src/model.dart';

class FixtureProject {
  FixtureProject(Map<String, String> files) {
    directory = Directory.systemTemp.createTempSync('anime flow architecture ');
    File(p.join(root, 'pubspec.yaml')).writeAsStringSync(
      'name: anime_flow\nenvironment:\n  sdk: ">=3.3.4 <4.0.0"\n',
    );
    final original = File(
      p.join(findProjectRoot(), '.dart_tool', 'package_config.json'),
    );
    final config =
        jsonDecode(original.readAsStringSync()) as Map<String, dynamic>;
    for (final raw in config['packages'] as List) {
      final package = raw as Map<String, dynamic>;
      final value = package['rootUri'] as String;
      package['rootUri'] = package['name'] == 'anime_flow'
          ? directory.uri.toString()
          : original.absolute.uri
                .resolve(value.endsWith('/') ? value : '$value/')
                .toString();
    }
    final target = File(p.join(root, '.dart_tool', 'package_config.json'));
    target.parent.createSync(recursive: true);
    target.writeAsStringSync(jsonEncode(config));
    for (final entry in files.entries) {
      write(entry.key, entry.value);
    }
  }
  late final Directory directory;
  String get root => directory.path;
  void write(String path, String content) {
    final file = File(p.join(root, path));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  void dispose() => directory.deleteSync(recursive: true);
}

ArchitectureSpec fixtureSpec({
  Set<String> publicB = const {},
  Set<String> uiB = const {},
  AccessMode mode = AccessMode.directApi,
  Map<String, Set<String>> generatedGroups = const {},
}) => ArchitectureSpec([
  ModuleSpec('core', 'lib/core', [
    SourceScope('lib/core/**', Responsibility.foundation, required: false),
  ]),
  for (final name in ['a', 'b'])
    ModuleSpec(
      name,
      'lib/features/$name',
      [
        SourceScope(
          'lib/features/$name/application/**',
          Responsibility.business,
          mode: AccessMode.repository,
          required: false,
        ),
        SourceScope(
          'lib/features/$name/domain/**',
          Responsibility.domain,
          required: false,
        ),
        SourceScope(
          'lib/features/$name/data/**',
          Responsibility.data,
          required: false,
        ),
        SourceScope(
          'lib/features/$name/presentation/providers/**',
          Responsibility.business,
          mode: mode,
          required: false,
        ),
        SourceScope(
          'lib/features/$name/presentation/widgets/**',
          Responsibility.ui,
          required: false,
        ),
        SourceScope(
          'lib/features/$name/api.dart',
          Responsibility.business,
          required: false,
        ),
      ],
      dependencies: name == 'a' ? {'b'} : {},
      apiEntries: name == 'b' ? publicB : {},
      uiEntries: name == 'b' ? uiB : {},
    ),
], generatedGroups: generatedGroups);
