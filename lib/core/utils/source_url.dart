String resolveSourceUrl(String baseUrl, String link) {
  final trimmed = link.trim();
  if (trimmed.isEmpty) return '';

  final base = Uri.parse(baseUrl.trim());
  var resolved = base.resolve(trimmed);
  if (base.scheme == 'https' &&
      resolved.scheme == 'http' &&
      resolved.host == base.host &&
      resolved.hasPort == base.hasPort &&
      (!resolved.hasPort || resolved.port == base.port)) {
    resolved = resolved.replace(scheme: 'https');
  }
  return resolved.toString();
}
