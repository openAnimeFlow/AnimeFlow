import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/features/recording/domain/recording_backend.dart';
import 'package:anime_flow/features/recording/infrastructure/ffmpeg_kit_runner.dart';
import 'package:anime_flow/features/recording/infrastructure/ffmpeg_recording_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory directory;
  late String input;
  late _Runner runner;
  late FfmpegRecordingBackend backend;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('recording_test_');
    input = p.join(directory.path, '中文 source with spaces.mp4');
    await File(input).writeAsString('fixture placeholder');
    runner = _Runner();
    backend = FfmpegRecordingBackend(runner: runner);
  });

  tearDown(() async => directory.delete(recursive: true));

  ClipExportRequest request({String id = 'clip', int? audio = 2}) =>
      ClipExportRequest(
        taskId: id,
        input: LocalRecordingInput(input),
        outputDirectory: directory.path,
        start: const Duration(seconds: 2),
        duration: const Duration(seconds: 3),
        videoStreamIndex: 0,
        audioStreamIndex: audio,
      );

  test(
      'publishes only after decode, preserving explicit audio selection and paths',
      () async {
    final handle = await backend.exportClip(request());
    final result = await handle.completed;
    expect(result.status, ExportStatus.savedLocal);
    expect(await File(result.localPath!).exists(), isTrue);
    expect(runner.exportArguments, contains(input));
    expect(runner.exportArguments, contains('0:2'));
    expect(runner.exportArguments, isNot(contains('0:a:0?')));
    expect(runner.decoded, isTrue);
    expect(
        await directory
            .list(recursive: true)
            .any((f) => f.path.contains('.partial.')),
        isFalse);
  });

  test('does not silently drop audio from an input containing audio', () async {
    final result =
        await (await backend.exportClip(request(audio: null))).completed;
    expect(result.status, ExportStatus.failed);
    expect(result.failure!.stage, ExportStage.preparing);
    expect(runner.exportArguments, isEmpty);
  });

  test('rejects network and unsafe task identifiers before native execution',
      () async {
    await expectLater(
        backend.probe('https://example.com/secret.mp4'), throwsArgumentError);
    await expectLater(
        backend.exportClip(request(id: '../escape')), throwsArgumentError);
    expect(runner.calls, 0);
  });

  test('zero decoded frames cannot become a saved clip', () async {
    runner.outputFrames = 0;
    final result = await (await backend.exportClip(request())).completed;
    expect(result.status, ExportStatus.failed);
    expect(result.failure!.stage, ExportStage.validating);
    expect(result.localPath, isNull);
    expect(
        await directory
            .list(recursive: true)
            .any((f) => f.path.endsWith('.mkv')),
        isFalse);
  });

  test('a decodable but truncated output is not published', () async {
    runner.outputDuration = '0.3';
    final result = await (await backend.exportClip(request())).completed;
    expect(result.status, ExportStatus.failed);
    expect(result.failure!.stage, ExportStage.validating);
    expect(result.localPath, isNull);
  });

  test('decode failure removes incomplete output even when probe succeeded',
      () async {
    runner.failDecode = true;
    final result = await (await backend.exportClip(request())).completed;
    expect(result.status, ExportStatus.failed);
    expect(result.failure!.stage, ExportStage.validating);
    expect(
        await directory
            .list(recursive: true)
            .any((f) => f.path.endsWith('.mkv')),
        isFalse);
  });

  test('null native return code is a failure, not successful export', () async {
    runner.failProbe = true;
    final result = await (await backend.exportClip(request())).completed;
    expect(result.status, ExportStatus.failed);
    expect(result.failure!.stage, ExportStage.preparing);
  });

  test(
      'cancel while session creation is pending waits for that session to stop',
      () async {
    runner.startGate = Completer<void>();
    final handle = await backend.exportClip(request());
    await runner.startEntered.future;
    await handle.cancel();
    runner.startGate!.complete();
    final result = await handle.completed;
    expect(result.status, ExportStatus.cancelled);
    expect(runner.cancelledCommands, 1);
    expect(runner.exportArguments, isEmpty);
  });

  test('concurrent exports with identical IDs use independent output files',
      () async {
    final a = await backend.exportClip(request());
    final b = await backend.exportClip(request());
    final results = await Future.wait([a.completed, b.completed]);
    expect(results.map((r) => r.status), everyElement(ExportStatus.savedLocal));
    expect(results[0].localPath, isNot(results[1].localPath));
  });

  test('probe rejects unavailable and nonfinite duration', () {
    for (final duration in ['N/A', 'NaN', 'Infinity', '0', '-1']) {
      expect(
          () => FfmpegRecordingBackend.parseProbe(jsonEncode({
                'format': {'duration': duration, 'format_name': 'mov'},
                'streams': [],
              })),
          throwsFormatException);
    }
  });
}

class _Runner implements FfmpegRunner {
  int calls = 0;
  int outputFrames = 75;
  String outputDuration = '3.0';
  bool failDecode = false;
  bool failProbe = false;
  bool decoded = false;
  int cancelledCommands = 0;
  List<String> exportArguments = [];
  Completer<void>? startGate;
  final startEntered = Completer<void>();

  @override
  Future<NativeCommand> start(
    List<String> arguments, {
    bool probe = false,
    void Function(Duration)? onTime,
  }) async {
    calls++;
    if (!startEntered.isCompleted) startEntered.complete();
    if (startGate != null) await startGate!.future;
    final isOutput = arguments.contains('-count_frames');
    if (probe) {
      return _Command(
          NativeCommandResult(
              failProbe ? null : 0,
              jsonEncode({
                'format': {
                  'duration': isOutput ? outputDuration : '10.0',
                  'format_name': 'matroska'
                },
                'streams': [
                  {
                    'index': 0,
                    'codec_type': 'video',
                    'codec_name': 'h264',
                    'nb_read_frames': '$outputFrames'
                  },
                  if (!isOutput)
                    {'index': 1, 'codec_type': 'audio', 'codec_name': 'aac'},
                  {
                    'index': isOutput ? 1 : 2,
                    'codec_type': 'audio',
                    'codec_name': 'aac',
                    'nb_read_frames': '$outputFrames'
                  },
                ],
              })),
          () => cancelledCommands++);
    }
    if (arguments.last == '-') {
      decoded = true;
      return _Command(NativeCommandResult(failDecode ? 1 : 0, ''),
          () => cancelledCommands++);
    }
    exportArguments = arguments;
    await File(arguments.last).writeAsString('partial');
    return _Command(
        const NativeCommandResult(0, ''), () => cancelledCommands++);
  }
}

class _Command implements NativeCommand {
  _Command(this.result, this.onCancel);
  final NativeCommandResult result;
  final void Function() onCancel;
  bool cancelled = false;
  @override
  Future<NativeCommandResult> get completed async =>
      cancelled ? const NativeCommandResult(255, '') : result;
  @override
  Future<void> cancel() async {
    cancelled = true;
    onCancel();
  }
}
