import 'model.dart';

/// 检查业务/UI 和导航装配边界；追踪重导出，防止聚合文件绕过检查。
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
    final targets = <String>{};
    void follow(String target) {
      if (!targets.add(target)) return;
      for (final exported in exports[target] ?? const <String>[]) {
        follow(exported);
      }
    }

    follow(edge.target);
    for (final target in targets.where(
      (target) => spec.disallowsDependency(edge.source, target),
    )) {
      final violation = ArchitectureViolation(
        'R10',
        edge.source,
        target,
        edge.kind,
        edge.line,
        '功能/共享代码不能依赖应用路由；导航契约不能依赖应用装配或功能实现。',
      );
      violations[violation.key] = violation;
    }
    if (spec.roleOf(edge.source) != Responsibility.business) continue;
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
