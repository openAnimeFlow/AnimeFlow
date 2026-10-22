import 'package:analyzer/dart/ast/ast.dart';
import 'package:glob/glob.dart';

enum Responsibility { business, ui, other }

class SourceScope {
  SourceScope(this.pattern, this.responsibility) : glob = Glob(pattern);
  final String pattern;
  final Glob glob;
  final Responsibility responsibility;
  bool matches(String path) => glob.matches(path);
}

class ArchitectureSpec {
  const ArchitectureSpec({
    this.scopes = const [],
    this.uiLibraries = const {},
    this.generatedGroups = const {},
  });

  /// 按顺序匹配，精确例外放在通用目录规则之前；未匹配文件仍参与循环检查。
  final List<SourceScope> scopes;
  final Set<String> uiLibraries;
  final Map<String, Set<String>> generatedGroups;
  static const rules = {'R03', 'R07'};

  Responsibility roleOf(String path) {
    for (final scope in scopes) {
      if (scope.matches(path)) return scope.responsibility;
    }
    return Responsibility.other;
  }

  bool isUi(String path) =>
      roleOf(path) == Responsibility.ui ||
      uiLibraries.any((pattern) => Glob(pattern).matches(path));

  /// feature 自动按路径识别，无需维护模块清单或允许依赖方向。
  String? featureOf(String path) {
    final parts = path.split('/');
    return parts.length >= 4 && parts[0] == 'lib' && parts[1] == 'features'
        ? parts[2]
        : null;
  }

  void validate(Iterable<String> paths) {
    final files = paths.toSet();
    if (files.isEmpty) throw StateError('架构扫描没有找到源码。');
    final grouped = <String>{};
    for (final group in generatedGroups.entries) {
      if (group.value.length < 2 || !files.containsAll(group.value)) {
        throw StateError('无效的生成代码分组：${group.key}');
      }
      for (final file in group.value) {
        if (!grouped.add(file)) throw StateError('生成代码分组重复：$file');
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
  const DependencyEdge(this.source, this.target, this.kind, this.line);
  final String source;
  final String target;
  final String kind;
  final int line;
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
}
