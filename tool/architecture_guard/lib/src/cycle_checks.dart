import 'model.dart';

List<ArchitectureViolation> checkCycles(
  DependencyGraph graph,
  ArchitectureSpec spec,
) {
  final groups = <String, String>{
    for (final group in spec.generatedGroups.entries)
      for (final file in group.value) file: 'generated:${group.key}',
  };
  String node(String path) => groups[path] ?? path;
  final adjacency = <String, Set<String>>{
    for (final library in graph.libraries) node(library): {},
  };
  final eligible = graph.edges
      .where(
        (e) =>
            graph.libraries.contains(e.target) &&
            !(groups.containsKey(e.source) &&
                groups[e.source] == groups[e.target]),
      )
      .toList();
  for (final edge in eligible) {
    adjacency[node(edge.source)]!.add(node(edge.target));
  }
  var next = 0;
  final indices = <String, int>{},
      low = <String, int>{},
      components = <String, int>{};
  final stack = <String>[], onStack = <String>{};
  final sizes = <int, int>{};
  void visit(String v) {
    indices[v] = low[v] = next++;
    stack.add(v);
    onStack.add(v);
    for (final w in adjacency[v]!) {
      if (!indices.containsKey(w)) {
        visit(w);
        if (low[w]! < low[v]!) low[v] = low[w]!;
      } else if (onStack.contains(w) && indices[w]! < low[v]!) {
        low[v] = indices[w]!;
      }
    }
    if (low[v] == indices[v]) {
      final id = sizes.length;
      var size = 0;
      String w;
      do {
        w = stack.removeLast();
        onStack.remove(w);
        components[w] = id;
        size++;
      } while (w != v);
      sizes[id] = size;
    }
  }

  for (final vertex in adjacency.keys) {
    if (!indices.containsKey(vertex)) visit(vertex);
  }
  final violations = [
    for (final edge in eligible)
      if (components[node(edge.source)] == components[node(edge.target)] &&
          (sizes[components[node(edge.source)]]! > 1 ||
              edge.source == edge.target))
        ArchitectureViolation(
          'R07',
          edge.source,
          edge.target,
          edge.kind,
          edge.line,
          '循环中的具体依赖边；通过契约/依赖注入拆开业务和实现。',
        ),
  ];
  // Feature-level cycles can exist without any individual file cycle.
  final featureEdges = eligible
      .where(
        (edge) =>
            edge.source.startsWith('lib/features/') &&
            edge.target.startsWith('lib/features/') &&
            spec.ownerOf(edge.source).module.name !=
                spec.ownerOf(edge.target).module.name,
      )
      .toList();
  adjacency.clear();
  for (final edge in featureEdges) {
    final from = spec.ownerOf(edge.source).module.name;
    final to = spec.ownerOf(edge.target).module.name;
    adjacency.putIfAbsent(from, () => {}).add(to);
    adjacency.putIfAbsent(to, () => {});
  }
  indices.clear();
  low.clear();
  components.clear();
  sizes.clear();
  next = 0;
  for (final vertex in adjacency.keys) {
    if (!indices.containsKey(vertex)) visit(vertex);
  }
  for (final edge in featureEdges) {
    final from = spec.ownerOf(edge.source).module.name;
    final to = spec.ownerOf(edge.target).module.name;
    if (components[from] == components[to]) {
      violations.add(
        ArchitectureViolation(
          'R07',
          edge.source,
          edge.target,
          edge.kind,
          edge.line,
          '功能模块循环中的具体依赖边；通过公开契约拆开双向业务依赖。',
        ),
      );
    }
  }
  return {for (final violation in violations) violation.key: violation}.values
      .toList();
}
