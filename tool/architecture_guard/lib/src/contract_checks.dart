import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:path/path.dart' as p;

import 'boundary_checks.dart';
import 'dependency_graph.dart';
import 'model.dart';

Future<List<ArchitectureViolation>> checkContracts(
  DependencyGraph graph,
  ArchitectureSpec spec,
) async {
  final uris = ProjectUris(graph.root);
  final collection = AnalysisContextCollection(
    includedPaths: [p.join(graph.root, 'lib')],
    sdkPath: uris.sdkPath(),
  );
  if (collection.contexts.length != 1) {
    await collection.dispose();
    throw StateError('R08: expected one project analysis context');
  }
  final violations = <String, ArchitectureViolation>{};
  try {
    for (final source in graph.units.values) {
      final path = p.normalize(p.join(graph.root, source.path));
      // Parts/generated dependencies can be excluded by analysis_options.yaml;
      // they still must be resolved through the project's analysis session.
      final result = await collection.contexts.single.currentSession
          .getResolvedUnit(path);
      if (result is! ResolvedUnitResult || !result.exists) {
        throw StateError(
          'R08 ${source.path}: semantic analysis did not resolve source',
        );
      }
      final errors = result.diagnostics.where(
        (e) => e.diagnosticCode.severity == DiagnosticSeverity.ERROR,
      );
      if (errors.isNotEmpty) {
        throw StateError(
          'R08 ${source.path}: semantic analysis failed: ${errors.take(5).join('; ')}',
        );
      }
      if (source.generated) continue;
      final owner = spec.ownerOf(source.library);
      final visitor = _ContractVisitor(source, owner, uris, violations);
      result.unit.accept(visitor);
      if (owner.module.apiEntries.contains(source.path)) {
        for (final element
            in result.libraryElement.exportNamespace.definedNames2.values) {
          visitor.checkExport(element);
        }
      }
    }
  } finally {
    await collection.dispose();
  }
  return violations.values.toList();
}

class _ContractVisitor extends GeneralizingAstVisitor<void> {
  _ContractVisitor(this.source, this.owner, this.uris, this.violations);
  final SourceUnit source;
  final Ownership owner;
  final ProjectUris uris;
  final Map<String, ArchitectureViolation> violations;
  bool get business => {
    Responsibility.business,
    Responsibility.domain,
    Responsibility.model,
  }.contains(owner.role);

  void report(String rule, String target, int offset, String message) {
    final violation = ArchitectureViolation(
      rule,
      source.library,
      target,
      'type',
      source.unit.lineInfo.getLocation(offset).lineNumber,
      message,
    );
    violations.putIfAbsent(violation.key, () => violation);
  }

  @override
  void visitNode(AstNode node) {
    if (business) {
      final type = switch (node) {
        NamedType() => node.type,
        Expression() => node.staticType,
        _ => null,
      };
      checkType(type, node.offset);
    }
    if (owner.role == Responsibility.ui && node is SimpleIdentifier) {
      final element = node.element;
      final uri = element?.library?.uri.toString();
      if (uri != null &&
          (element is ExecutableElement ||
              element is PropertyAccessorElement)) {
        final target = uris.normalize(uri, source.path);
        if (isApi(target)) {
          report(
            'R04',
            '$target#${element!.name}',
            node.offset,
            'Widget/展示代码不直接请求 API；通过业务 Provider 调用。',
          );
        }
      }
    }
    super.visitNode(node);
  }

  void checkType(DartType? type, int offset, [Set<DartType>? seen]) {
    if (type == null) return;
    seen ??= <DartType>{};
    if (!seen.add(type)) return;
    if (type is InterfaceType) {
      for (final candidate in [type, ...type.allSupertypes]) {
        final element = candidate.element;
        final library = element.library.uri.toString();
        if (library.startsWith('package:flutter/') &&
                {
                  'Widget',
                  'BuildContext',
                  'Element',
                  'State',
                }.contains(element.name) ||
            library.startsWith('package:flutter_riverpod/') &&
                element.name == 'WidgetRef') {
          report(
            'R09',
            '$library#${element.name}',
            offset,
            '业务层只返回数据和业务状态；将 Widget/BuildContext 等 UI 使用移至展示或渲染适配层。',
          );
          break;
        }
      }
      for (final argument in type.typeArguments) {
        checkType(argument, offset, seen);
      }
    } else if (type is FunctionType) {
      checkType(type.returnType, offset, seen);
      for (final parameter in type.formalParameters) {
        checkType(parameter.type, offset, seen);
      }
    } else if (type is RecordType) {
      for (final field in [...type.positionalFields, ...type.namedFields]) {
        checkType(field.type, offset, seen);
      }
    } else if (type is TypeParameterType) {
      checkType(type.bound, offset, seen);
    }
  }

  void checkExport(Element element) {
    if (element is InterfaceElement) {
      checkType(element.thisType, 0);
    }
    final library = element.library?.uri.toString();
    if (library == null) return;
    final target = uris.normalize(library, source.path);
    // Public interfaces must not leak implementation types through signatures.
    void signature(DartType type, [Set<DartType>? seen]) {
      seen ??= {};
      if (!seen.add(type)) return;
      checkType(type, 0);
      if (type is InterfaceType) {
        final uri = uris.normalize(
          type.element.library.uri.toString(),
          source.path,
        );
        if (uri.startsWith('lib/features/') &&
            (uri.contains('/data/') ||
                uri.contains('/infrastructure/') ||
                uri.contains('/presentation/pages/') ||
                uri.contains('/presentation/widgets/'))) {
          report('R06', '$uri#${type.element.name}', 0, '公开接口类型泄漏具体实现。');
        }
        for (final argument in type.typeArguments) {
          signature(argument, seen);
        }
      } else if (type is FunctionType) {
        signature(type.returnType, seen);
        for (final parameter in type.formalParameters) {
          signature(parameter.type, seen);
        }
      } else if (type is RecordType) {
        for (final field in [...type.positionalFields, ...type.namedFields]) {
          signature(field.type, seen);
        }
      }
    }

    if (target.startsWith('lib/')) {
      if (element is FunctionTypedElement) signature(element.type);
      if (element is VariableElement) signature(element.type);
      if (element is InterfaceElement) {
        for (final field in element.fields) {
          signature(field.type);
        }
        for (final method in element.methods) {
          signature(method.type);
        }
        for (final constructor in element.constructors) {
          signature(constructor.type);
        }
      }
      if (element is TypeAliasElement) signature(element.aliasedType);
    }
  }
}
