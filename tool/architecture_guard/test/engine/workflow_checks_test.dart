@Tags(['architecture'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'package:anime_flow_architecture_guard/src/dependency_graph.dart';

void main() {
  final root = findProjectRoot();
  Map workflow(String name) => loadYaml(
    File(p.join(root, '.github/workflows/$name.yml')).readAsStringSync(),
  ) as Map;
  final platforms = ['ios', 'android', 'windows', 'linux', 'macos'];
  Iterable<Map> checkouts(Map job) => (job['steps'] as List).cast<Map>().where(
    (s) => (s['uses'] as String? ?? '').startsWith('actions/checkout@'),
  );
  test('build and merge queue use a shared quality gate and matching SHA', () {
    final build = workflow('build');
    expect((build['on'] as Map).containsKey('merge_group'), isTrue);
    final jobs = build['jobs'] as Map;
    expect(jobs.containsKey('flutter-test'), isFalse);
    expect(jobs['quality']['uses'], './.github/workflows/quality.yml');
    expect(jobs['quality']['with']['source_sha'], r'${{ github.sha }}');
    for (final platform in platforms) {
      final job = jobs['build-$platform'] as Map;
      expect(job['needs'], 'quality');
      expect(checkouts(job).single['with']['ref'], r'${{ github.sha }}');
    }
  });
  test(
    'reusable checks pin source, lock both packages and run tagged tests',
    () {
      final quality = workflow('quality');
      expect(quality['permissions']['contents'], 'read');
      expect(
        quality['on']['workflow_call']['inputs']['source_sha']['required'],
        isTrue,
      );
      final jobs = quality['jobs'] as Map;
      expect(jobs['architecture']['strategy']['matrix']['os'], [
        'ubuntu-latest',
        'windows-latest',
      ]);
      for (final name in ['architecture', 'unit-tests']) {
        expect(
          checkouts(jobs[name] as Map).single['with']['ref'],
          r'${{ inputs.source_sha || github.sha }}',
        );
      }
      final steps = (jobs['architecture']['steps'] as List).cast<Map>();
      expect(
        steps.any(
          (s) =>
              s['working-directory'] == 'tool/architecture_guard' &&
              s['run'] == 'dart pub get --enforce-lockfile',
        ),
        isTrue,
      );
      expect(
        steps.any(
          (s) => (s['run'] as String? ?? '').contains(
            'test/architecture --tags architecture',
          ),
        ),
        isTrue,
      );
      expect(
        (jobs['unit-tests']['steps'] as List).cast<Map>().any(
          (s) =>
              s['run'] == 'flutter test --no-pub --exclude-tags architecture',
        ),
        isTrue,
      );
      expect(
        steps.any(
          (s) =>
              s.containsKey('env') &&
              (s['env'] as Map).values.any(
                (v) => v.toString().contains('secrets.'),
              ),
        ),
        isFalse,
      );
    },
  );
  test(
    'release resolves a tag once and gates every checkout/build/publication',
    () {
      final jobs = workflow('release')['jobs'] as Map;
      expect(
        jobs['resolve-source']['steps'].last['env']['INPUT_TAG'],
        r'${{ inputs.tag }}',
      );
      expect(jobs['quality']['needs'], 'resolve-source');
      expect(
        jobs['quality']['with']['source_sha'],
        r'${{ needs.resolve-source.outputs.source_sha }}',
      );
      for (final platform in platforms) {
        final job = jobs['build-$platform'] as Map;
        expect(job['needs'], ['resolve-source', 'quality']);
        expect(
          checkouts(job).single['with']['ref'],
          r'${{ needs.resolve-source.outputs.source_sha }}',
        );
      }
      final release = jobs['release'] as Map;
      expect(
        release['needs'],
        containsAll([
          'resolve-source',
          'quality',
          ...platforms.map((p) => 'build-$p'),
        ]),
      );
      expect(release['if'], contains("needs.quality.result == 'success'"));
      expect(release['if'], contains("!contains(needs.*.result, 'failure')"));
      expect(release['if'], contains("!contains(needs.*.result, 'cancelled')"));
      for (final platform in platforms) {
        expect(
          release['if'],
          contains("needs.build-$platform.result == 'success'"),
        );
      }
      expect(
        checkouts(release).single['with']['ref'],
        r'${{ needs.resolve-source.outputs.source_sha }}',
      );
      final publish = (release['steps'] as List).cast<Map>().singleWhere(
        (s) => (s['uses'] as String? ?? '').startsWith(
          'softprops/action-gh-release@',
        ),
      );
      expect(
        publish['with']['tag_name'],
        r'${{ needs.resolve-source.outputs.tag }}',
      );
      expect(
        publish['with']['target_commitish'],
        r'${{ needs.resolve-source.outputs.source_sha }}',
      );
      expect(publish['with']['files'], contains('source-metadata.json'));
    },
  );
  test('tag resolver handles real lightweight/annotated tags and rejects invalid sources', () async {
    final directory = Directory.systemTemp.createTempSync(
      'architecture release ',
    );
    Future<ProcessResult> git(List<String> arguments) =>
        Process.run('git', arguments, workingDirectory: directory.path);
    Future<void> gitOk(List<String> arguments) async {
      final result = await git(arguments);
      expect(result.exitCode, 0, reason: result.stderr.toString());
    }

    try {
      await gitOk(['init']);
      await gitOk(['config', 'user.name', 'Architecture Fixture']);
      await gitOk(['config', 'user.email', 'architecture@example.invalid']);
      await gitOk([
        '-c',
        'commit.gpgsign=false',
        'commit',
        '--allow-empty',
        '-m',
        'fixture',
      ]);
      await gitOk(['-c', 'tag.gpgsign=false', 'tag', 'v-light']);
      await gitOk([
        '-c',
        'tag.gpgsign=false',
        'tag',
        '-a',
        'v-annotated',
        '-m',
        'fixture',
      ]);
      await gitOk(['remote', 'add', 'origin', directory.path]);
      final sha = (await git(['rev-parse', 'HEAD'])).stdout.toString().trim();
      var bash = 'bash';
      if (Platform.isWindows) {
        final where = await Process.run('where.exe', ['git']);
        final gitPath = where.stdout
            .toString()
            .split(RegExp(r'\r?\n'))
            .first
            .trim();
        bash = p.normalize(p.join(p.dirname(gitPath), '..', 'bin', 'bash.exe'));
        expect(
          File(bash).existsSync(),
          isTrue,
          reason: 'Git for Windows bash is required',
        );
      }
      final script = p
          .join(root, 'tool/ci/resolve_release_source.sh')
          .replaceAll(r'\', '/');
      for (final tag in [
        'v-light',
        'v-annotated',
        'missing-tag',
        'bad tag',
        r'$(touch injected)',
        '',
      ]) {
        final output = File(p.join(directory.path, 'outputs.txt'));
        output.writeAsStringSync('');
        final result = await Process.run(
          bash,
          [script],
          workingDirectory: directory.path,
          environment: {
            'GITHUB_EVENT_NAME': 'workflow_dispatch',
            'INPUT_TAG': tag,
            'GITHUB_OUTPUT': output.path.replaceAll(r'\', '/'),
          },
        );
        if (tag == 'v-light' || tag == 'v-annotated') {
          expect(result.exitCode, 0, reason: result.stderr.toString());
          expect(output.readAsStringSync(), 'source_sha=$sha\ntag=$tag\n');
        } else {
          expect(result.exitCode, isNot(0));
          expect(output.readAsStringSync(), isEmpty);
        }
      }
      expect(File(p.join(directory.path, 'injected')).existsSync(), isFalse);
      final output = File(p.join(directory.path, 'push-output.txt'));
      final result = await Process.run(
        bash,
        [script],
        workingDirectory: directory.path,
        environment: {
          'GITHUB_EVENT_NAME': 'push',
          'GITHUB_REF_TYPE': 'tag',
          'GITHUB_REF_NAME': 'v-light',
          'GITHUB_OUTPUT': output.path.replaceAll(r'\', '/'),
        },
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(output.readAsStringSync(), contains('source_sha=$sha'));
    } finally {
      directory.deleteSync(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
