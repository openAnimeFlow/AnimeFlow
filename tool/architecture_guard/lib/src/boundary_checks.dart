import 'model.dart';

bool isApi(String path) =>
    path.startsWith('lib/core/network/api/') ||
    path.startsWith('lib/core/network/clients/');
bool isImplementation(String path) =>
    path.startsWith('package:dio/') ||
    path.startsWith('package:hive_ce/') ||
    isApi(path);

List<ArchitectureViolation> checkBoundaries(
  DependencyGraph graph,
  ArchitectureSpec spec,
) {
  final violations = <ArchitectureViolation>[];
  final visited = <String>{};
  for (final edge in graph.edges) {
    final source = spec.ownerOf(edge.source);
    final targets = <String>{};
    bool domainAllows(String target) {
      if (target.startsWith('dart:')) {
        return !{
          'dart:ui',
          'dart:ui_web',
          'dart:io',
          'dart:ffi',
          'dart:html',
        }.contains(target);
      }
      if (target.startsWith('package:')) {
        return spec.domainPackages.any(
          (name) => target.startsWith('package:$name/'),
        );
      }
      if (!graph.libraries.contains(target)) return false;
      final owner = spec.ownerOf(target);
      return owner.role == Responsibility.domain ||
          owner.role == Responsibility.model ||
          spec.domainCoreTypes.contains(target);
    }

    // Always follow project re-exports, including every conditional branch.
    void follow(String target) {
      if (!targets.add(target)) return;
      for (final exported in graph.exportedFrom(target)) {
        follow(exported.target);
      }
      if (source.role == Responsibility.domain && domainAllows(target)) {
        for (final dependency in graph.edges.where(
          (e) => e.source == target && e.kind == 'import',
        )) {
          follow(dependency.target);
        }
      }
    }

    follow(edge.target);
    void report(String rule, String target, String message) {
      final violation = ArchitectureViolation(
        rule,
        edge.source,
        target,
        edge.kind,
        edge.line,
        message,
      );
      if (visited.add(violation.key)) violations.add(violation);
    }

    for (final target in targets) {
      final destination = graph.libraries.contains(target)
          ? spec.ownerOf(target)
          : null;
      final featureTarget = target.startsWith('lib/features/');
      if ((source.module.name == 'core' ||
              source.module.name.startsWith('shared_')) &&
          featureTarget) {
        report('R01', target, '基础/共享能力不能依赖 feature；将业务依赖移至功能或装配处。');
      }
      if (source.module.name == 'core' &&
          (target.startsWith('lib/app/') &&
                  !target.startsWith('lib/app/localization/') ||
              target.startsWith('lib/shared/widgets/'))) {
        report('R01', target, 'core 不能依赖应用装配或公共 UI。');
      }
      if ({Responsibility.data, Responsibility.adapter}.contains(source.role) &&
          destination != null &&
          (destination.role == Responsibility.ui ||
              destination.role == Responsibility.business &&
                  !spec.dataContracts.containsKey(target))) {
        report('R02', target, '数据/适配实现不能依赖页面或业务状态编排。');
      }
      if (source.role == Responsibility.business &&
          (destination?.role == Responsibility.ui ||
              edge.source.contains('/application/') &&
                  target.contains('/presentation/'))) {
        report('R03', target, '业务状态/流程不能反向依赖展示层；拆出业务状态或契约。');
      }
      if (spec.dataContracts.containsKey(edge.source) &&
          destination != null &&
          {
            Responsibility.ui,
            Responsibility.business,
            Responsibility.data,
            Responsibility.adapter,
          }.contains(destination.role)) {
        report('R02', target, '批准的数据失效信号不能执行业务流程或依赖数据实现。');
      }
      if (source.role == Responsibility.domain && !domainAllows(target)) {
        report('R05', target, '领域契约只依赖纯业务类型，不依赖 UI、状态管理或具体实现。');
      }
      if (source.role == Responsibility.business &&
          source.mode == AccessMode.repository &&
          edge.source.contains('/presentation/') &&
          (isImplementation(target) ||
              destination != null &&
                  {
                    Responsibility.data,
                    Responsibility.adapter,
                  }.contains(destination.role))) {
        report('R04', target, '该复杂用例通过业务入口/Repository 契约访问数据。');
      }
      // Internal references are checked at the direct entry boundary, not after
      // following the implementation of a legitimate approved public API.
      if (target == edge.target &&
          featureTarget &&
          destination != null &&
          source.module.name != destination.module.name &&
          (edge.source.startsWith('lib/features/') ||
              source.module.name == 'app')) {
        final app = source.module.name == 'app';
        if ((!app &&
                !source.module.dependencies.contains(
                  destination.module.name,
                )) ||
            !(destination.module.apiEntries.contains(target) ||
                app && destination.module.pageEntries.contains(target))) {
          report('R06', target, '跨功能需使用批准的业务入口和登记的依赖方向。');
        }
      }
      if (source.module.apiEntries.contains(edge.source) &&
          destination != null &&
          {
            Responsibility.data,
            Responsibility.adapter,
            Responsibility.ui,
          }.contains(destination.role)) {
        report('R06', target, '公开业务入口不能重导出数据、适配或页面实现。');
      }
    }
  }
  return violations;
}
