import 'package:analyzer/dart/ast/ast.dart';
import 'package:glob/glob.dart';

enum Responsibility {
  composition,
  foundation,
  model,
  ui,
  business,
  domain,
  data,
  adapter,
}

enum AccessMode { directApi, repository }

class SourceScope {
  SourceScope(
    this.pattern,
    this.responsibility, {
    this.mode,
    this.required = true,
  }) : glob = Glob(pattern);
  final String pattern;
  final Glob glob;
  final Responsibility responsibility;
  final AccessMode? mode;
  final bool required;
  bool matches(String path) => glob.matches(path);
}

class ModuleSpec {
  const ModuleSpec(
    this.name,
    this.root,
    this.scopes, {
    this.dependencies = const {},
    this.apiEntries = const {},
    this.pageEntries = const {},
    this.uiEntries = const {},
  });
  final String name;
  final String root;
  final List<SourceScope> scopes;
  final Set<String> dependencies;
  final Set<String> apiEntries;
  final Set<String> pageEntries;
  // Explicit reusable presentation entries, available only to UI consumers.
  final Set<String> uiEntries;
}

class Ownership {
  const Ownership(this.module, this.scope);
  final ModuleSpec module;
  final SourceScope scope;
  Responsibility get role => scope.responsibility;
  AccessMode? get mode => scope.mode;
}

class ArchitectureSpec {
  const ArchitectureSpec(
    this.modules, {
    this.generatedGroups = const {},
    this.dataContracts = const {},
    this.domainPackages = const {},
    this.domainCoreTypes = const {},
    this.strictScopes = const {},
    this.compositionOnly = const {},
  });
  final List<ModuleSpec> modules;
  // Only generator-owned cycles inside these exact groups are collapsed.
  final Map<String, Set<String>> generatedGroups;
  final Map<String, String> dataContracts;
  final Set<String> domainPackages;
  final Set<String> domainCoreTypes;
  // Scoped rules cannot be frozen again after a business migration.
  final Map<String, Set<String>> strictScopes;
  final Set<String> compositionOnly;
  static const rules = {
    'R01',
    'R02',
    'R03',
    'R04',
    'R05',
    'R06',
    'R07',
    'R08',
    'R09',
  };
  static const strictRules = {'R01', 'R02', 'R08'};

  bool isStrict(String rule, String source, {String? target}) =>
      strictRules.contains(rule) ||
      rule == 'R04' && compositionOnly.contains(target) ||
      (strictScopes[rule]?.any(
            (pattern) =>
                Glob(pattern).matches(source) ||
                rule == 'R06' &&
                    target != null &&
                    Glob(pattern).matches(target),
          ) ??
          false);

  Ownership ownerOf(String path) {
    final matches = [
      for (final module in modules)
        for (final scope in module.scopes)
          if (scope.matches(path)) Ownership(module, scope),
    ];
    if (matches.length != 1) {
      throw StateError(
        'R08 $path: expected one responsibility, found ${matches.length}',
      );
    }
    return matches.single;
  }

  void validate(Iterable<String> paths) {
    final files = paths.toSet();
    if (files.isEmpty) throw StateError('R08: source scan is empty');
    for (final entry in compositionOnly) {
      if (!files.contains(entry) ||
          !{
            Responsibility.adapter,
            Responsibility.composition,
          }.contains(ownerOf(entry).role)) {
        throw StateError('R08: invalid composition-only implementation $entry');
      }
    }
    for (final entry in strictScopes.entries) {
      if (!rules.contains(entry.key) || entry.value.isEmpty) {
        throw StateError('R08: invalid scoped strict rule ${entry.key}');
      }
      for (final pattern in entry.value) {
        if (!files.any(Glob(pattern).matches)) {
          throw StateError('R08: no source matches strict scope $pattern');
        }
      }
    }
    final names = modules.map((m) => m.name).toSet();
    if (names.length != modules.length) {
      throw StateError('R08: duplicate module');
    }
    for (final module in modules) {
      if (module.scopes.isEmpty || module.root.isEmpty) {
        throw StateError('R08: empty module ${module.name}');
      }
      for (final dependency in module.dependencies) {
        if (!names.contains(dependency) || dependency == module.name) {
          throw StateError(
            'R08: invalid dependency ${module.name} -> $dependency',
          );
        }
      }
      for (final scope in module.scopes) {
        if (scope.required && !files.any(scope.matches)) {
          throw StateError('R08: no source matches ${scope.pattern}');
        }
        if (scope.mode != null &&
            scope.responsibility != Responsibility.business) {
          throw StateError('R08: access mode requires business responsibility');
        }
      }
      for (final entry in {
        ...module.apiEntries,
        ...module.pageEntries,
        ...module.uiEntries,
      }) {
        if (!files.contains(entry) ||
            ownerOf(entry).module.name != module.name) {
          throw StateError('R08: missing or misplaced public entry $entry');
        }
      }
      for (final entry in module.uiEntries) {
        if (ownerOf(entry).role != Responsibility.ui) {
          throw StateError(
            'R08: presentation entry must have UI responsibility',
          );
        }
      }
    }
    for (final file in files) {
      final owner = ownerOf(file);
      if (file != owner.module.root &&
          !file.startsWith('${owner.module.root}/')) {
        throw StateError('R08: $file is outside declared module root');
      }
    }
    for (final contract in dataContracts.entries) {
      if (!files.contains(contract.key) ||
          contract.value.trim().isEmpty ||
          ownerOf(contract.key).role != Responsibility.business) {
        throw StateError('R08: invalid shared data contract ${contract.key}');
      }
    }
    for (final path in domainCoreTypes) {
      if (!files.contains(path) ||
          ownerOf(path).role != Responsibility.foundation) {
        throw StateError('R08: invalid pure core type $path');
      }
    }
    for (final group in generatedGroups.entries) {
      if (group.value.length < 2 || !files.containsAll(group.value)) {
        throw StateError('R08: invalid generated group ${group.key}');
      }
    }
  }
}

class SourceUnit {
  SourceUnit(this.path, this.unit, {this.libraryPath, this.generated = false});
  final String path;
  final CompilationUnit unit;
  String? libraryPath;
  final bool generated;
  String get library => libraryPath ?? path;
}

class DependencyEdge {
  const DependencyEdge(
    this.source,
    this.target,
    this.kind,
    this.line, {
    this.physicalSource,
  });
  final String source;
  final String target;
  final String kind;
  final int line;
  final String? physicalSource;
  String get key => '$source|$target|$kind';
}

class ArchitectureViolation {
  const ArchitectureViolation(
    this.rule,
    this.source,
    this.target,
    this.kind,
    this.line,
    this.message,
  );
  final String rule, source, target, kind, message;
  final int line;
  String get key => '$rule|$source|$target|$kind';
  Map<String, Object> toJson() => {
    'rule': rule,
    'source': source,
    'target': target,
    'kind': kind,
    'line': line,
    'message': message,
  };
  @override
  String toString() => '$rule $source:$line -> $target ($kind): $message';
}

class DependencyGraph {
  DependencyGraph(this.root, this.units, this.edges);
  final String root;
  final Map<String, SourceUnit> units;
  final List<DependencyEdge> edges;
  Set<String> get libraries => units.values.map((u) => u.library).toSet();
  Iterable<String> get handwritten =>
      units.values.where((u) => !u.generated).map((u) => u.path);

  Iterable<DependencyEdge> exportedFrom(String path) =>
      edges.where((e) => e.source == path && e.kind == 'export');
}
