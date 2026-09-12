import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Fingerprint actual built native artifacts; the pub archive hash alone does
/// not identify binaries downloaded separately by plugin build scripts.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    stderr.writeln(
        'Usage: dart run tool/recording_native_manifest.dart <native directory> <output.json>');
    exitCode = 64;
    return;
  }
  final root = Directory(arguments[0]).absolute;
  final files = await root
      .list(recursive: true, followLinks: false)
      .where((entry) => entry is File)
      .cast<File>()
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  final entries = <Map<String, Object>>[];
  for (final file in files) {
    final name = p.basename(file.path);
    if (!['.dll', '.exe', '.so', '.dylib', '.aar', '.a']
            .contains(p.extension(name)) &&
        !name.contains('.so.') &&
        !file.path.contains('.framework${p.separator}')) {
      continue;
    }
    entries.add({
      'path': p.relative(file.path, from: root.path),
      'bytes': await file.length(),
      'sha256': (await sha256.bind(file.openRead()).first).toString(),
    });
  }
  if (entries.isEmpty) throw StateError('No native artifacts found');
  final output = File(arguments[1]);
  await output.parent.create(recursive: true);
  await output.writeAsString(const JsonEncoder.withIndent('  ').convert({
    'plugin': 'ffmpeg_kit_flutter_new',
    'pluginVersion': '4.6.2',
    'pluginArchiveSha256':
        '112ca70a36babc2951cddc879990aad98956b75acb69cdc3fbd2d16bfc941753',
    'artifacts': entries,
  }));
  stdout.writeln(
      'Wrote ${entries.length} fingerprints to ${output.absolute.path}');
}
