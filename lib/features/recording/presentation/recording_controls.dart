import 'package:flutter/material.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/media_cache/domain/hls_snapshot.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import '../application/recording_controller.dart';
import 'recording_tasks_page.dart';

class RecordingControls extends StatelessWidget {
  const RecordingControls(
      {super.key, required this.session, required this.playing});
  final PlaySession session;
  final bool playing;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
        listenable: Listenable.merge([session.recording, session.cacheStatus]),
        builder: (context, _) {
          final marker = session.recording.value;
          final active = marker.status != RecordingMarkerStatus.idle;
          final supported =
              session.cacheStatus.value == MediaCacheIssue.ready ||
                  session.cacheStatus.value == MediaCacheIssue.localFile;
          final label = marker.status == RecordingMarkerStatus.preparing
              ? l10n.recordingPreparing
              : active
                  ? '${l10n.recordingStop} ${recordingTime(marker.end - marker.start)}'
                  : supported
                      ? l10n.recordingStart
                      : l10n.recordingUnavailable;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
                tooltip: label,
                onPressed: active || (supported && playing)
                    ? () async {
                        await session.toggleRecording();
                        final message = session.recording.value.message;
                        if (context.mounted && message != null) {
                          NotificationToast.show(message, title: l10n.tip);
                        }
                      }
                    : null,
                color: active ? Colors.redAccent : Colors.white,
                disabledColor: Colors.white38,
                icon: Icon(active
                    ? Icons.stop_circle_outlined
                    : Icons.fiber_manual_record)),
            if (active)
              Text(recordingTime(marker.end - marker.start),
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 12)),
            IconButton(
                tooltip: l10n.recordingFiles,
                color: Colors.white70,
                icon: const Icon(Icons.video_library_outlined),
                onPressed: () {
                  session.pauseForRouteCover();
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const RecordingTasksPage()));
                }),
          ]);
        });
  }
}
