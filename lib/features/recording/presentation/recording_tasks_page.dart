import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import '../application/recording_service.dart';
import '../domain/recording_backend.dart';

class RecordingTasksPage extends StatefulWidget {
  const RecordingTasksPage({super.key, this.service});
  final RecordingService? service;
  @override
  State<RecordingTasksPage> createState() => _RecordingTasksPageState();
}

class _RecordingTasksPageState extends State<RecordingTasksPage> {
  late final Future<RecordingService> _service = widget.service == null
      ? sharedRecordingService()
      : Future.value(widget.service);
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
        appBar: AppBar(title: Text(l10n.recordingFiles)),
        body: FutureBuilder<RecordingService>(
            future: _service,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(l10n.recordingLoadFailed));
              }
              final service = snapshot.data;
              if (service == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListenableBuilder(
                  listenable: service,
                  builder: (context, _) {
                    final tasks = service.tasks;
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(16),
                              child: SelectableText(
                                  '${l10n.recordingLocalOnly}\n${service.directory.path}')),
                          Expanded(
                              child: tasks.isEmpty
                                  ? Center(child: Text(l10n.recordingEmpty))
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      itemCount: tasks.length,
                                      itemBuilder: (context, index) =>
                                          _task(context, service, tasks[index]),
                                    )),
                        ]);
                  });
            }));
  }

  Widget _task(
      BuildContext context, RecordingService service, RecordingTask task) {
    final l10n = AppLocalizations.of(context);
    final status = switch (task.status) {
      RecordingTaskStatus.queued => l10n.recordingQueued,
      RecordingTaskStatus.saved => l10n.recordingSaved,
      RecordingTaskStatus.failed => l10n.recordingFailed,
      RecordingTaskStatus.cancelled => l10n.recordingCancelled,
      RecordingTaskStatus.exporting => switch (task.stage) {
          ExportStage.preparing => l10n.recordingPreparing,
          ExportStage.validating => l10n.recordingValidating,
          ExportStage.saving => l10n.recordingSaving,
          ExportStage.exporting => l10n.recordingExporting,
        },
    };
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                    '${recordingTime(task.start)} – ${recordingTime(task.end)} · $status'),
                if (task.busy)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(
                          value: task.stage == ExportStage.exporting &&
                                  task.progress > Duration.zero
                              ? (task.progress.inMilliseconds /
                                      task.duration.inMilliseconds)
                                  .clamp(0.0, 1.0)
                              : null)),
                if (task.error != null)
                  Text(task.error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                if (task.persistenceError != null) Text(task.persistenceError!),
                if (task.localPath != null) SelectableText(task.localPath!),
                Wrap(spacing: 8, children: [
                  if (task.busy)
                    TextButton(
                        onPressed: () => _action(() => service.cancel(task)),
                        child: Text(l10n.cancel)),
                  if (task.status == RecordingTaskStatus.saved)
                    TextButton.icon(
                        onPressed: () => _action(() async {
                              final result =
                                  await OpenFile.open(task.localPath);
                              if (result.type != ResultType.done) {
                                throw StateError('open failed');
                              }
                            }),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.recordingOpen)),
                  if (task.canRetry) ...[
                    TextButton(
                        onPressed: () => service.retry(task),
                        child: Text(l10n.retry)),
                    TextButton(
                        onPressed: () =>
                            service.retry(task, encoding: ClipEncoding.h264Aac),
                        child: Text(l10n.recordingTranscodeRetry)),
                  ],
                  if (!task.busy)
                    TextButton(
                        onPressed: () async {
                          if (task.status == RecordingTaskStatus.saved) {
                            final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                        title: Text(l10n.confirmDelete),
                                        content:
                                            Text(l10n.recordingDeletePrompt),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text(l10n.cancel)),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(l10n.delete)),
                                        ]));
                            if (confirmed != true) return;
                          }
                          await _action(() => service.remove(task,
                              deleteFile:
                                  task.status == RecordingTaskStatus.saved));
                        },
                        child: Text(task.status == RecordingTaskStatus.saved
                            ? l10n.delete
                            : l10n.recordingDiscard)),
                ]),
              ],
            )));
  }

  Future<void> _action(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).recordingActionFailed)));
      }
    }
  }
}

String recordingTime(Duration duration) {
  final seconds = duration.inSeconds;
  return '${seconds ~/ 3600}:${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}
