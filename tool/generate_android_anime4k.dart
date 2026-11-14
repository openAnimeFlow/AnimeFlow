// Converts the application MPV preset and the x2 test fixture to GLES 3.
// Run from the repository root; --check verifies the committed assets without writing.
import 'dart:io';
import 'dart:convert';

void main(List<String> arguments) {
  generateEfficiency(arguments.contains('--check'));
  generateEfficiency(arguments.contains('--check'), x2: true);
}

void generateEfficiency(bool check, {bool x2 = false}) {
  final output =
      x2 ? 'test/fixtures/video_shaders/android' : 'assets/shaders/android';
  // Read the MPV preset itself so its file order cannot silently diverge.
  final preset = File(
          'lib/features/play/infrastructure/player/media_kit/mpv_upscale_shaders.dart')
      .readAsStringSync();
  final list = RegExp(r'_efficiencyShaders = \[([\s\S]*?)\];')
      .firstMatch(preset)!
      .group(1)!;
  final names = x2
      ? ['Anime4K_Upscale_CNN_x2_S.glsl']
      : RegExp(r"'([^']+\.glsl)'")
          .allMatches(list)
          .map((m) => m.group(1)!)
          .toList();
  if (!x2 && names.length != 7) {
    throw StateError('Review the changed MPV efficiency preset');
  }
  final prefix = x2 ? 'x2' : 'efficiency';
  final passes = <Map<String, Object>>[];
  for (final name in names) {
    final source = File('assets/shaders/$name')
        .readAsStringSync()
        .replaceAll('\r\n', '\n');
    final sections = source.split('//!DESC ');
    final license = sections.first.trimRight();
    for (final section in sections.skip(1)) {
      final lines = section.trimRight().split('\n');
      final directives = <String, List<String>>{};
      for (final line in lines.where((l) => l.startsWith('//!'))) {
        final space = line.indexOf(' ');
        final key = line.substring(3, space);
        if (!{'HOOK', 'BIND', 'SAVE', 'WIDTH', 'HEIGHT', 'WHEN', 'COMPONENTS'}
            .contains(key)) {
          throw StateError('Unsupported directive in $name: $line');
        }
        directives.putIfAbsent(key, () => []).add(line.substring(space + 1));
      }
      String value(String key, String fallback) =>
          directives[key]?.single ?? fallback;
      final hook = value('HOOK', '');
      if (hook != 'MAIN' && hook != 'PREKERNEL') {
        throw StateError('Unsupported hook $hook');
      }
      final kernel =
          lines.skip(1).where((l) => !l.startsWith('//!')).join('\n');
      final bindings = <Map<String, Object>>[];
      final aliases = StringBuffer();
      // MPV also exposes the hook point name when HOOKED is bound (e.g. MAIN_texOff).
      final allowed = {...?directives['BIND']};
      if (allowed.contains('HOOKED')) allowed.add(hook);
      final used = RegExp(r'\b(\w+)_(texOff|tex|pos|size|pt)\b')
          .allMatches(kernel)
          .map((m) => m.group(1)!)
          .toSet();
      for (final binding in used) {
        if (!allowed.contains(binding)) {
          throw StateError('Unbound texture $binding in $name');
        }
        final sampler =
            RegExp('\\b${binding}_(texOff|tex)\\b').hasMatch(kernel);
        final dimensions =
            RegExp('\\b${binding}_(texOff|size|pt)\\b').hasMatch(kernel);
        bindings.add(
            {'name': binding, 'sampler': sampler, 'dimensions': dimensions});
        if (sampler) aliases.writeln('uniform sampler2D u_$binding;');
        if (dimensions) aliases.writeln('uniform vec2 s_$binding;');
        aliases.writeln('''#define ${binding}_pos vTexCoord
#define ${binding}_size s_$binding
#define ${binding}_pt (vec2(1.0) / s_$binding)
#define ${binding}_tex(pos) texture(u_$binding, pos)
#define ${binding}_texOff(offset) texture(u_$binding, vTexCoord + (offset) / s_$binding)''');
      }
      final asset = '${prefix}_${passes.length}.glsl';
      writeGenerated(
          '$output/$asset',
          '''#version 300 es
$license

// Generated from assets/shaders/$name. Do not edit.
// ${lines.first}
precision highp float;
in vec2 vTexCoord;
out vec4 outColor;
$aliases
$kernel
void main() { outColor = hook(); }
''',
          check);
      passes.add({
        'asset': asset,
        'source': name,
        'description': lines.first,
        'hook': hook,
        'bindings': bindings,
        'save': value('SAVE', 'HOOKED'),
        'width': value('WIDTH', 'HOOKED.w'),
        'height': value('HEIGHT', 'HOOKED.h'),
        'when': value('WHEN', '1'),
        'components': int.parse(value('COMPONENTS', '4')),
      });
    }
  }
  // Hook scheduling, not textual file order: PREKERNEL runs after all MAIN passes.
  final ordered = [
    for (final hook in ['MAIN', 'PREKERNEL'])
      ...passes.where((p) => p['hook'] == hook)
  ];
  writeGenerated('$output/$prefix.json',
      '${const JsonEncoder.withIndent('  ').convert(ordered)}\n', check);
  stdout.writeln(
      'Anime4K efficiency: ${names.length} files, ${passes.length} passes verified.');
}

void writeGenerated(String path, String contents, bool check) {
  contents = contents.split('\n').map((line) => line.trimRight()).join('\n');
  final file = File(path);
  if (check) {
    if (!file.existsSync() ||
        file.readAsStringSync().replaceAll('\r\n', '\n') != contents) {
      throw StateError('$path is stale; regenerate Android Anime4K assets');
    }
  } else {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }
}
