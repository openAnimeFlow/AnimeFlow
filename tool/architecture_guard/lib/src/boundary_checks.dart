import 'model.dart';

/// 业务文件不得导入或重导出 UI；追踪重导出，防止聚合文件绕过检查。
List<ArchitectureViolation> checkBoundaries(
  DependencyGraph graph,
  ArchitectureSpec spec,
) {
  final exports = <String, List<String>>{};
  for (final edge in graph.edges.where((edge) => edge.kind == 'export')) {
    exports.putIfAbsent(edge.source, () => []).add(edge.target);
  }
  final violations = <String, ArchitectureViolation>{};
  for (final edge in graph.edges) {
    if (spec.roleOf(edge.source) != Responsibility.business) continue;
    final targets = <String>{};
    void follow(String target) {
      if (!targets.add(target)) return;
      for (final exported in exports[target] ?? const <String>[]) {
        follow(exported);
      }
    }

    follow(edge.target);
    for (final target in targets.where(spec.isUi)) {
      final violation = ArchitectureViolation(
        'R03',
        edge.source,
        target,
        edge.kind,
        edge.line,
        '业务层不能导入或重导出 UI 文件。',
      );
      violations[violation.key] = violation;
    }
  }
  return violations.values.toList();
}
