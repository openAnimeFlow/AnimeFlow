import 'dart:async';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/session.dart';

class NativeCommandResult {
  const NativeCommandResult(this.returnCode, this.output);

  final int? returnCode;
  final String output;
  bool get succeeded => returnCode == 0;
  bool get cancelled => returnCode == 255;
}

abstract interface class NativeCommand {
  Future<NativeCommandResult> get completed;
  Future<void> cancel();
}

/// Infrastructure seam for native execution; business code uses RecordingBackend.
abstract interface class FfmpegRunner {
  Future<NativeCommand> start(
    List<String> arguments, {
    bool probe = false,
    void Function(Duration)? onTime,
  });
}

class FfmpegKitRunner implements FfmpegRunner {
  const FfmpegKitRunner();

  @override
  Future<NativeCommand> start(
    List<String> arguments, {
    bool probe = false,
    void Function(Duration)? onTime,
  }) async {
    final completion = Completer<NativeCommandResult>();
    Future<void> finish(Session session) async {
      try {
        final code = await session.getReturnCode();
        // FFprobe JSON is delivered through the native log/output channel.
        final output = await session.getOutput() ?? '';
        completion.complete(NativeCommandResult(code?.getValue(), output));
      } catch (error, stack) {
        completion.completeError(error, stack);
      }
    }

    final Session session;
    if (probe) {
      session = await FFprobeKit.executeWithArgumentsAsync(arguments, finish);
    } else {
      session = await FFmpegKit.executeWithArgumentsAsync(
        arguments,
        finish,
        null,
        (statistics) => onTime?.call(
          Duration(milliseconds: statistics.getTime()),
        ),
      );
    }
    final id = session.getSessionId();
    if (id == null) {
      throw StateError('FFmpegKit did not return a session ID');
    }
    return _KitCommand(id, completion.future);
  }
}

class _KitCommand implements NativeCommand {
  _KitCommand(this.id, this.completed);

  final int id;
  @override
  final Future<NativeCommandResult> completed;

  @override
  Future<void> cancel() => FFmpegKit.cancel(id);
}
