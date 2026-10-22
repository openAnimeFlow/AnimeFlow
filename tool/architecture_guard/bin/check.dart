import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:anime_flow_architecture_guard/architecture_spec.dart';
import 'package:anime_flow_architecture_guard/src/boundary_checks.dart';
import 'package:anime_flow_architecture_guard/src/contract_checks.dart';
import 'package:anime_flow_architecture_guard/src/cycle_checks.dart';
import 'package:anime_flow_architecture_guard/src/dependency_graph.dart';
import 'package:anime_flow_architecture_guard/src/legacy_checks.dart';
import 'package:anime_flow_architecture_guard/src/model.dart';

Future<void> main(List<String> arguments) async {
  try {
    final watch = Stopwatch()..start();
    final root = findProjectRoot(arguments.isEmpty ? null : arguments.single);
    final spec = projectArchitecture();
    final graph = collectDependencies(root, spec);
    final violations = <String, ArchitectureViolation>{
      for (final v in [
        ...checkBoundaries(graph, spec),
        ...checkCycles(graph, spec),
        ...await checkContracts(graph, spec),
      ])
        v.key: v,
    }.values.toList()..sort((a, b) => a.key.compareTo(b.key));
    final summary = {
      'sourceFiles': graph.units.length,
      'handwrittenFiles': graph.handwritten.length,
      'libraries': graph.libraries.length,
      'modules': spec.modules.length,
      'dependencies': graph.edges.length,
      'elapsedMs': watch.elapsedMilliseconds,
      'ruleCounts': {
        for (final rule in ArchitectureSpec.rules)
          rule: violations.where((v) => v.rule == rule).length,
      },
    };
    final report = File(p.join(root, 'build', 'architecture', 'report.json'));
    report.parent.createSync(recursive: true);
    report.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'summary': summary,
        'violations': violations.map((v) => v.toJson()).toList(),
      }),
    );
    stdout.writeln('Architecture: ${jsonEncode(summary)}');
    final result = compareLegacy(
      violations,
      readLegacy(
        File(p.join(root, 'test', 'architecture', 'legacy_dependencies.json')),
      ),
      sources: graph.libraries,
      spec: spec,
    );
    stdout.writeln(
      'Registered legacy edges: ${result.registered}; new: ${result.newViolations.length}; stale: ${result.stale.length}',
    );
    if (!result.passes) throw StateError(result.toString());
  } catch (error, stack) {
    stderr.writeln(error);
    stderr.writeln(stack);
    exitCode = 1;
  }
}
