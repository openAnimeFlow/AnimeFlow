import 'dart:convert';
import 'dart:io';

// Work around video_player_avfoundation's missing platform-macro import when
// compiling with SPM (which does not provide CocoaPods' prefix header).
// Run after `flutter pub get`, before `flutter build macos`.
void main(List<String> arguments) {
  if (arguments.length > 1) {
    stderr.writeln(
      'Usage: dart tool/patch_avfoundation_spm.dart [package_config.json]',
    );
    exitCode = 1;
    return;
  }
  try {
    final changed = patchAvfoundationSpm(
      File(arguments.isEmpty
          ? '.dart_tool/package_config.json'
          : arguments.single),
    );
    stdout.writeln(changed
        ? 'Patched video_player_avfoundation: imported TargetConditionals.h.'
        : 'video_player_avfoundation already imports TargetConditionals.h.');
  } catch (error) {
    stderr.writeln('AVFoundation SPM patch failed: $error');
    exitCode = 1;
  }
}

/// Returns false when the dependency already contains the required import.
/// Fails on unexpected source layouts so dependency upgrades cannot silently
/// bypass the workaround. No cache path or package version is hard-coded.
bool patchAvfoundationSpm(File packageConfig) {
  final config =
      jsonDecode(packageConfig.readAsStringSync()) as Map<String, dynamic>;
  final packages = (config['packages'] as List).cast<Map<String, dynamic>>();
  final package = packages
      .where(
        (entry) => entry['name'] == 'video_player_avfoundation',
      )
      .firstOrNull;
  if (package == null) {
    throw StateError(
        'video_player_avfoundation is missing from package_config');
  }
  final root = Directory.fromUri(
    packageConfig.absolute.uri.resolve(package['rootUri'] as String),
  );
  final header = File.fromUri(root.uri.resolve(
    'darwin/video_player_avfoundation/Sources/'
    'video_player_avfoundation_objc/include/'
    'video_player_avfoundation_objc/FVPViewProvider.h',
  ));
  if (!header.existsSync()) {
    throw StateError('Expected header not found: ${header.path}');
  }
  final source = header.readAsStringSync();
  final guard =
      RegExp(r'^#if\s+TARGET_OS_OSX\s*$', multiLine: true).firstMatch(source);
  if (guard == null) {
    throw StateError('Platform guard changed; review ${header.path}');
  }
  final preamble = source.substring(0, guard.start);
  if (RegExp(r'#\s*(?:import|include)\s*[<"]TargetConditionals\.h[>"]')
      .hasMatch(preamble)) {
    return false;
  }
  final newline = source.contains('\r\n') ? '\r\n' : '\n';
  header.writeAsStringSync(
    '$preamble#import <TargetConditionals.h>$newline$newline'
    '${source.substring(guard.start)}',
  );
  return true;
}
