import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/patch_avfoundation_spm.dart';

void main() {
  late Directory temporary;
  late File config;
  late File header;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('avfoundation-spm-test-');
    config = File('${temporary.path}/.dart_tool/package_config.json');
    config.parent.createSync(recursive: true);
    config.writeAsStringSync(jsonEncode({
      'packages': [
        {'name': 'video_player_avfoundation', 'rootUri': '../cache/plugin/'}
      ],
    }));
    header = File('${temporary.path}/cache/plugin/darwin/'
        'video_player_avfoundation/Sources/video_player_avfoundation_objc/'
        'include/video_player_avfoundation_objc/FVPViewProvider.h');
    header.parent.createSync(recursive: true);
  });

  tearDown(() => temporary.deleteSync(recursive: true));

  for (final newline in ['\n', '\r\n']) {
    test('patches before platform selection and is idempotent ($newline)', () {
      final source = [
        '// License',
        '',
        '#if TARGET_OS_OSX',
        '@import FlutterMacOS;',
        '#else',
        '@import Flutter;',
        '#endif',
        '',
      ].join(newline);
      header.writeAsStringSync(source);
      expect(patchAvfoundationSpm(config), isTrue);
      final patched = header.readAsStringSync();
      expect(
          patched,
          source.replaceFirst('#if TARGET_OS_OSX',
              '#import <TargetConditionals.h>$newline$newline#if TARGET_OS_OSX'));
      expect(patchAvfoundationSpm(config), isFalse);
      expect(header.readAsStringSync(), patched);
    });
  }

  test('resolves absolute package URI and accepts an upstream fix', () {
    config.writeAsStringSync(jsonEncode({
      'packages': [
        {
          'name': 'video_player_avfoundation',
          'rootUri': Directory('${temporary.path}/cache/plugin').uri.toString(),
        }
      ],
    }));
    const source =
        '#include <TargetConditionals.h>\n#if TARGET_OS_OSX\n#endif\n';
    header.writeAsStringSync(source);
    expect(patchAvfoundationSpm(config), isFalse);
    expect(header.readAsStringSync(), source);
  });

  test('fails rather than silently skipping changed dependency layouts', () {
    expect(() => patchAvfoundationSpm(config), throwsStateError);
    header.writeAsStringSync('// Different upstream header\n');
    expect(() => patchAvfoundationSpm(config), throwsStateError);
    expect(header.readAsStringSync(), '// Different upstream header\n');
    config.writeAsStringSync('{"packages":[]}');
    expect(() => patchAvfoundationSpm(config), throwsStateError);
  });
}
