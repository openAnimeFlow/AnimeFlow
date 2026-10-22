import 'dart:convert';
import 'dart:io';

import 'model.dart';

class LegacyResult {
  const LegacyResult(this.newViolations, this.stale, this.registered);
  final List<ArchitectureViolation> newViolations;
  final Set<String> stale;
  final int registered;
  bool get passes => newViolations.isEmpty && stale.isEmpty;
  @override
  String toString() => [
    ...newViolations.map((v) => v.toString()),
    ...stale.map((key) => 'Resolved legacy entry must be removed: $key'),
  ].join('\n');
}

LegacyResult compareLegacy(
  List<ArchitectureViolation> violations,
  Map<String, dynamic> json, {
  required Set<String> sources,
  DateTime? now,
}) {
  if (json.keys.any((k) => !{'schemaVersion', 'violations'}.contains(k)) ||
      json['schemaVersion'] != 1 ||
      json['violations'] is! List) {
    throw StateError('invalid legacy schema');
  }
  final today = now ?? DateTime.now().toUtc();
  final date = DateTime.utc(today.year, today.month, today.day);
  final registered = <String>{};
  for (final raw in json['violations'] as List) {
    if (raw is! Map ||
        raw.keys.any(
          (k) => !{
            'rule',
            'source',
            'target',
            'kind',
            'reason',
            'owner',
            'cleanupTask',
            'reviewBy',
          }.contains(k),
        )) {
      throw StateError('malformed legacy entry');
    }
    for (final field in [
      'rule',
      'source',
      'target',
      'kind',
      'reason',
      'owner',
      'cleanupTask',
      'reviewBy',
    ]) {
      if (raw[field] is! String || (raw[field] as String).trim().isEmpty) {
        throw StateError('missing legacy metadata $field');
      }
    }
    if (!ArchitectureSpec.rules.contains(raw['rule'])) {
      throw StateError('停用或未知的规则不能登记：${raw['rule']}');
    }
    if (!sources.contains(raw['source']) ||
        !{'import', 'export'}.contains(raw['kind']) ||
        (raw['source'] as String).contains(r'\') ||
        (raw['target'] as String).contains(r'\')) {
      throw StateError('invalid legacy dependency path/kind');
    }
    final review = DateTime.tryParse(raw['reviewBy'] as String);
    if (review == null ||
        review.toIso8601String().substring(0, 10) != raw['reviewBy'] ||
        DateTime.utc(review.year, review.month, review.day).isBefore(date)) {
      throw StateError(
        'expired or invalid legacy review date: ${raw['reviewBy']}',
      );
    }
    final key =
        "${raw['rule']}|${raw['source']}|${raw['target']}|${raw['kind']}";
    if (!registered.add(key)) {
      throw StateError('duplicate legacy entry $key');
    }
  }
  final current = {for (final v in violations) v.key: v};
  return LegacyResult(
    current.entries
        .where((e) => !registered.contains(e.key))
        .map((e) => e.value)
        .toList(),
    registered.difference(current.keys.toSet()),
    registered.length,
  );
}

Map<String, dynamic> readLegacy(File file) {
  if (!file.existsSync()) {
    throw StateError(
      'missing legacy register. Review build/architecture/report.json; tests never create or refresh it.',
    );
  }
  final json = jsonDecode(file.readAsStringSync());
  if (json is! Map<String, dynamic>) {
    throw StateError('legacy register must be an object');
  }
  return json;
}
