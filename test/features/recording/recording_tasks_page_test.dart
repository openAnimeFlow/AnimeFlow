import 'dart:io';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/recording/application/recording_controller.dart';
import 'package:anime_flow/features/recording/application/recording_service.dart';
import 'package:anime_flow/features/recording/domain/recording_backend.dart';
import 'package:anime_flow/features/recording/presentation/recording_tasks_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'recording_test_support.dart';

void main() {
  testWidgets('failed task exposes retry and discard at narrow width',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late RecordingService service;
    late Directory root;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('recording-ui-');
      final backend = ControlledRecordingBackend();
      service = RecordingService(directory: root, backend: backend);
      final controller =
          RecordingController(serviceFactory: () async => service);
      await controller.start(
          title: 'Episode 1',
          position: Duration.zero,
          localPath: '${root.path}/source.mp4');
      controller.updatePosition(const Duration(seconds: 3));
      controller.freeze();
      controller.dispose();
      await eventually(() => backend.handles.isNotEmpty);
      backend.handles.single.finish(ExportStatus.failed);
      await eventually(() => !service.tasks.single.busy);
    });
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: RecordingTasksPage(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('Episode 1'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Retry as H.264/AAC'), findsOneWidget);
    expect(find.textContaining('Export failed'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      await tester.tap(find.text('Discard and release cache'));
      await eventually(() => service.tasks.isEmpty);
    });
    await tester.pumpAndSettle();
    expect(find.text('No recorded clips'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
    await tester.runAsync(() => root.delete(recursive: true));
  });
}
