import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'model.dart';

String findProjectRoot([String? start]) {
  var directory = Directory(
    p.normalize(p.absolute(start ?? Directory.current.path)),
  );
  while (true) {
    final pubspec = File(p.join(directory.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final value = loadYaml(pubspec.readAsStringSync());
      if (value is Map && value['name'] == 'anime_flow') {
        return directory.path;
      }
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('pubspec.yaml not found');
    }
    directory = parent;
  }
}

class ProjectUris {
  ProjectUris(this.root) {
    final config = File(p.join(root, '.dart_tool', 'package_config.json'));
    if (!config.existsSync()) {
      throw StateError('run flutter pub get first');
    }
    final json = jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
    for (final package in json['packages'] as List<dynamic>) {
      final value = package as Map<String, dynamic>;
      final rootUri = value['rootUri'] as String;
      final packageRoot = config.absolute.uri.resolve(
        rootUri.endsWith('/') ? rootUri : '$rootUri/',
      );
      packages[value['name'] as String] = packageRoot.resolve(
        value['packageUri'] as String? ?? 'lib/',
      );
    }
    if (!packages.containsKey('anime_flow')) {
      throw StateError('package config lacks anime_flow');
    }
  }
  final String root;
  final Map<String, Uri> packages = {};
  late final Set<String> sdkLibraries = () {
    final metadata = jsonDecode(
      File(p.join(sdkPath(), 'lib', 'libraries.json')).readAsStringSync(),
    ) as Map;
    final libraries = <String>{};
    for (final value in metadata.values) {
      if (value is Map && value['libraries'] is Map) {
        libraries.addAll(
          (value['libraries'] as Map).keys.map((name) => 'dart:$name'),
        );
      }
    }
    final sky = packages['sky_engine'];
    if (sky != null) {
      final embedder = File.fromUri(sky.resolve('_embedder.yaml'));
      if (embedder.existsSync()) {
        final extra = loadYaml(embedder.readAsStringSync()) as Map;
        libraries.addAll((extra['embedded_libs'] as Map).keys.cast<String>());
      }
    }
    return libraries;
  }();

  String relative(String path) =>
      p.relative(p.normalize(path), from: root).replaceAll(r'\', '/');

  String normalize(String uri, String source) {
    final parsed = Uri.parse(uri);
    if (parsed.hasFragment || parsed.hasQuery) {
      throw StateError('invalid source URI $uri');
    }
    if (parsed.scheme == 'dart') {
      if (!sdkLibraries.contains(uri)) {
        throw StateError('$source: unknown SDK library $uri');
      }
      return uri;
    }
    Uri resolved;
    if (parsed.scheme == 'package') {
      final slash = parsed.path.indexOf('/');
      if (slash < 1) throw StateError('invalid package URI $uri');
      final name = parsed.path.substring(0, slash);
      final base = packages[name];
      if (base == null) throw StateError('$source: unknown package $name');
      resolved = base.resolve(parsed.path.substring(slash + 1));
      if (!File.fromUri(resolved).existsSync()) {
        throw StateError('$source: dependency does not exist: $uri');
      }
      if (name != 'anime_flow') return uri;
    } else if (parsed.scheme.isEmpty || parsed.scheme == 'file') {
      resolved = parsed.scheme == 'file'
          ? parsed
          : File(p.join(root, source)).absolute.uri.resolveUri(parsed);
    } else {
      throw StateError('$source: unsupported dependency $uri');
    }
    final path = p.normalize(p.fromUri(resolved));
    if (!p.isWithin(p.join(root, 'lib'), path)) {
      throw StateError('$source: dependency escapes project lib: $uri');
    }
    if (!File(path).existsSync()) {
      throw StateError('$source: missing $uri');
    }
    return relative(path);
  }

  String sdkPath() {
    final candidates = <String>[];
    final flutter = packages['flutter'];
    if (flutter != null) {
      candidates.add(
        p.normalize(
          p.join(
            p.fromUri(flutter),
            '..',
            '..',
            '..',
            'bin',
            'cache',
            'dart-sdk',
          ),
        ),
      );
    }
    var parent = Directory(p.dirname(Platform.resolvedExecutable));
    while (true) {
      candidates.add(parent.path);
      candidates.add(p.join(parent.path, 'bin', 'cache', 'dart-sdk'));
      if (parent.parent.path == parent.path) break;
      parent = parent.parent;
    }
    for (final candidate in candidates) {
      if (File(p.join(candidate, 'lib', 'libraries.json')).existsSync() &&
          Directory(p.join(candidate, 'bin')).existsSync()) {
        return candidate;
      }
    }
    throw StateError('cannot locate the Dart SDK for SDK URI validation');
  }
}

DependencyGraph collectDependencies(String root, ArchitectureSpec spec) {
  root = p.normalize(p.absolute(root));
  final uris = ProjectUris(root);
  final directory = Directory(p.join(root, 'lib'));
  if (!directory.existsSync()) {
    throw StateError('lib directory does not exist');
  }
  final files =
      directory
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final units = <String, SourceUnit>{};
  final generated = spec.generatedGroups.values
      .expand((group) => group)
      .toSet();
  for (final file in files) {
    final path = uris.relative(file.absolute.path);
    final result = parseString(
      content: file.readAsStringSync(),
      path: file.absolute.path,
      throwIfDiagnostics: false,
    );
    if (result.errors.isNotEmpty) {
      throw StateError(
        '$path: source parsing failed: ${result.errors.join('; ')}',
      );
    }
    units[path] = SourceUnit(
      path,
      result.unit,
      generated:
          path.endsWith('.g.dart') ||
          path.startsWith('lib/shared/widgets/bbcode/generated/') ||
          generated.contains(path),
    );
  }
  if (units.keys.map((path) => path.toLowerCase()).toSet().length !=
      units.length) {
    throw StateError('case-colliding source paths are not portable');
  }
  // part 归属声明它的 library，不作为独立循环节点。
  final partOwners = <String, String>{};
  for (final source in units.values) {
    for (final directive in source.unit.directives.whereType<PartDirective>()) {
      final value = directive.uri.stringValue;
      if (value == null) {
        throw StateError('${source.path}: invalid part URI');
      }
      final target = uris.normalize(value, source.path);
      if (!units.containsKey(target) || partOwners.containsKey(target)) {
        throw StateError('missing part or multiple library owners: $target');
      }
      partOwners[target] = source.path;
    }
  }
  for (final source in units.values) {
    final isPart = source.unit.directives.any((d) => d is PartOfDirective);
    final owner = partOwners[source.path];
    if (isPart != (owner != null)) {
      throw StateError(
        '${source.path}: inconsistent part/library relationship',
      );
    }
    source.libraryPath = owner;
  }
  spec.validate(
    units.values.where((u) => u.libraryPath == null).map((u) => u.path),
  );
  final edges = <DependencyEdge>[];
  for (final source in units.values) {
    for (final directive
        in source.unit.directives.whereType<NamespaceDirective>()) {
      final literals = [
        directive.uri,
        ...directive.configurations.map((c) => c.uri),
      ];
      for (final literal in literals) {
        final value = literal.stringValue;
        if (value == null) {
          throw StateError('${source.path}: invalid import/export');
        }
        var target = uris.normalize(value, source.path);
        if (target.startsWith('lib/') && !units.containsKey(target)) {
          throw StateError(
            '${source.path}: missing or case-mismatched project dependency $target',
          );
        }
        if (units.containsKey(target)) target = units[target]!.library;
        edges.add(
          DependencyEdge(
            source.library,
            target,
            directive is ExportDirective ? 'export' : 'import',
            source.unit.lineInfo.getLocation(literal.offset).lineNumber,
          ),
        );
      }
    }
  }
  return DependencyGraph(root, units, edges);
}
