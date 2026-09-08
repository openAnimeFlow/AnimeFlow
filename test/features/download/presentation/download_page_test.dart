import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/download/application/download_manager.dart';
import 'package:anime_flow/features/download/presentation/pages/download_page.dart';
import 'package:anime_flow/features/download/presentation/providers/download_provider.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_record.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Controller extends DownloadController {
  _Controller(this.records);
  final List<DownloadRecord> records;
  @override
  DownloadState build() => DownloadState(records: records);
  void publish() => state = DownloadState(records: List.of(records));
}

class _Manager implements IDownloadManager {
  @override
  String? getLocalMediaPath(DownloadEpisode? episode) =>
      episode?.localMediaPath.isNotEmpty == true
          ? episode!.localMediaPath
          : null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DownloadEpisode _episode(String url, double progress) => DownloadEpisode(
      episodeUrl: url,
      bangumiEpisodeId: 1,
      episodeSort: 1,
      episodeIndex: 1,
      episodeTitle: url,
      lineIndex: 0,
      sourceName: 'Source',
      status: DownloadStatus.downloading,
      progressPercent: progress,
    );

DownloadRecord _record(int id, DownloadEpisode episode) => DownloadRecord(
      subjectId: id,
      subjectName: 'Subject $id',
      subjectCover: '',
      sourceName: 'Source',
      sourceBaseUrl: 'https://example.test',
      episodes: {episode.episodeUrl: episode},
      createdAt: DateTime(2026),
    );

void main() {
  late _Controller controller;
  Future<void> mount(WidgetTester tester) async {
    controller = _Controller([
      _record(1, _episode('First', 20)),
      _record(2, _episode('Second', 30)),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        downloadControllerProvider.overrideWith(() => controller),
        downloadManagerProvider.overrideWithValue(_Manager()),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DownloadPage(),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets(
      'progress and status changes do not rebuild the page or other card',
      (tester) async {
    await mount(tester);
    final scaffold = tester.widget(find.byType(Scaffold));
    final firstHeader = tester.widget(find.text('Subject 1'));
    final secondHeader = tester.widget(find.text('Subject 2'));
    final otherProgress = tester
        .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator))
        .last;
    controller.records.first.episodes['First']!.progressPercent = 55;
    controller.publish();
    await tester.pump();
    expect(tester.widget(find.byType(Scaffold)), same(scaffold));
    expect(tester.widget(find.text('Subject 1')), same(firstHeader));
    expect(tester.widget(find.text('Subject 2')), same(secondHeader));
    final progress = tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator));
    expect(progress.first.value, 0.55);
    expect(progress.last, same(otherProgress));

    controller.records.first.episodes['First']!.status = DownloadStatus.paused;
    controller.publish();
    await tester.pump();
    expect(tester.widget(find.byType(Scaffold)), same(scaffold));
    expect(tester.widget(find.text('Subject 2')), same(secondHeader));
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacement objects, error changes and local paths stay current',
      (tester) async {
    await mount(tester);
    final replacement = _episode('First', 75)..status = DownloadStatus.failed;
    controller.records[0] = _record(1, replacement);
    controller.publish();
    await tester.pump();
    replacement.errorMessage = 'New failure detail';
    controller.publish();
    await tester.pump();
    expect(find.textContaining('New failure detail'), findsOneWidget);

    replacement.status = DownloadStatus.completed;
    controller.publish();
    await tester.pump();
    replacement.localMediaPath = 'download.mp4';
    controller.publish();
    await tester.pump();
    final play = find.widgetWithIcon(IconButton, Icons.play_arrow_rounded);
    expect(tester.widget<IconButton>(play.first).onPressed, isNotNull);
    controller.records.removeAt(0);
    controller.publish();
    await tester.pump();
    expect(find.text('Subject 1'), findsNothing);
    expect(find.text('Subject 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resuming a collapsed record expands it after in-place mutation',
      (tester) async {
    await mount(tester);
    final episode = controller.records.first.episodes['First']!;
    episode.status = DownloadStatus.paused;
    controller.publish();
    await tester.pump();
    await tester.tap(find.text('Subject 1'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('First')), findsNothing);
    episode.status = DownloadStatus.pending;
    controller.publish();
    await tester.pump();
    expect(find.byKey(const ValueKey('First')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
