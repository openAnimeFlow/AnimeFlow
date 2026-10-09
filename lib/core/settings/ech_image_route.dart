class EchImageRoute {
  EchImageRoute({required this.host, List<String> fixedIps = const []})
      : fixedIps = List.unmodifiable(fixedIps);

  final String host;
  final List<String> fixedIps;
}
