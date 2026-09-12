import 'dart:async';
import 'package:anime_flow/features/recording/domain/recording_backend.dart';

class ControlledRecordingBackend implements RecordingBackend {
  final requests = <ClipExportRequest>[];
  final handles = <ControlledExportHandle>[];
  Completer<void>? probeGate;
  Completer<void>? exportGate;
  bool multiAudio = false;
  @override
  Future<MediaProbeResult> probe(String localPath) =>
      probeInput(LocalRecordingInput(localPath));
  @override
  Future<MediaProbeResult> probeInput(RecordingInput input) async {
    await probeGate?.future;
    return MediaProbeResult(
        duration: const Duration(seconds: 100),
        format: 'mpegts',
        streams: [
          const MediaStreamInfo(index: 0, type: 'video', codec: 'h264'),
          const MediaStreamInfo(index: 2, type: 'audio', codec: 'aac'),
          if (multiAudio)
            const MediaStreamInfo(index: 3, type: 'audio', codec: 'aac'),
        ]);
  }

  @override
  Future<ExportHandle> exportClip(ClipExportRequest request) async {
    requests.add(request);
    final handle = ControlledExportHandle(request.taskId);
    handles.add(handle);
    await exportGate?.future;
    return handle;
  }
}

class ControlledExportHandle implements ExportHandle {
  ControlledExportHandle(this.id);
  final String id;
  bool cancelCalled = false;
  final done = Completer<ExportResult>();
  final events = StreamController<ExportProgress>.broadcast();
  @override
  Stream<ExportProgress> get progress => events.stream;
  @override
  Future<ExportResult> get completed => done.future;
  @override
  Future<void> cancel() async {
    cancelCalled = true;
  }

  void finish(ExportStatus status, {String? path}) {
    done.complete(ExportResult(taskId: id, status: status, localPath: path));
    unawaited(events.close());
  }
}

Future<void> eventually(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Condition not reached');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
