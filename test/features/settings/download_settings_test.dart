import 'dart:io';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/localization/app_localizations_delegates.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/settings/presentation/pages/download_settings.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart';

class _DirectoryPicker extends FilePicker {
  String? selected;
  bool fails = false;
  int calls = 0;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async {
    calls++;
    if (fails) throw PlatformException(code: 'picker_failed');
    return selected;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('anime_flow/download_storage');
  late Directory temp;
  late _DirectoryPicker picker;
  var granted = true;
  var permissionCalls = 0;
  var nativePickerCalls = 0;
  var writable = true;

  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('download_settings_test_');
    Hive.init(temp.path);
    Storage.setting = await Hive.openBox<dynamic>('download_settings');
  });

  tearDownAll(() async {
    await Hive.close();
    await temp.delete(recursive: true);
  });

  setUp(() async {
    await Storage.setting.put(DownloadKey.downloadDirectory, temp.path);
    picker = _DirectoryPicker();
    FilePicker.platform = picker;
    granted = true;
    permissionCalls = 0;
    nativePickerCalls = 0;
    writable = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'restoreAccess':
          return <String, String>{};
        case 'selectDirectory':
          nativePickerCalls++;
          if (picker.fails) throw PlatformException(code: 'picker_failed');
          final selected = picker.selected;
          return selected == null
              ? null
              : {
                  'path': selected,
                  'paths': {selected: selected}
                };
        case 'verifyWritable':
          if (!writable) throw PlatformException(code: 'not_writable');
          return null;
        case 'requestAccess':
          permissionCalls++;
          return granted;
        default:
          throw MissingPluginException(call.method);
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void testDirectorySelection(String description, WidgetTesterCallback callback,
      {Set<TargetPlatform> platforms = const {TargetPlatform.android}}) {
    testWidgets(description, callback,
        variant: TargetPlatformVariant(platforms));
  }

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        home: const DownloadSettingsPage(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder locationTile() => find.ancestor(
        of: find.text('Resource download location'),
        matching: find.byType(ListTile),
      );

  Future<void> select(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.tap(locationTile());
      await tester.pump();
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
        if (tester.widget<ListTile>(locationTile()).onTap != null) return;
      }
      fail('Directory selection did not finish');
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testDirectorySelection(
      'Android saves a writable folder and removes the write probe',
      (tester) async {
    final target = Directory('${temp.path}/selected')..createSync();
    picker.selected = target.path;
    await mount(tester);
    expect(find.byIcon(Icons.drive_file_move_outline), findsOneWidget);
    await select(tester);
    expect(permissionCalls, 1);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), target.path);
    expect(find.text(target.path), findsOneWidget);
    expect(target.listSync(), isEmpty);
  });

  testDirectorySelection(
      'denied storage access retains the location and skips the picker',
      (tester) async {
    granted = false;
    await mount(tester);
    await select(tester);
    expect(picker.calls, 0);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), temp.path);
    expect(
        find.text('Grant storage access before changing the download location'),
        findsOneWidget);
  });

  testDirectorySelection(
      'cancelling the picker retains the configured location', (tester) async {
    await mount(tester);
    await select(tester);
    expect(picker.calls, 1);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), temp.path);
  });

  testDirectorySelection('a path that cannot contain downloads is rejected',
      (tester) async {
    final file = File('${temp.path}/not_a_directory')
      ..writeAsStringSync('keep');
    picker.selected = file.path;
    await mount(tester);
    await select(tester);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), temp.path);
    expect(file.readAsStringSync(), 'keep');
    expect(
        find.text(
            'Cannot write to the selected folder. Choose another download location'),
        findsOneWidget);
  });

  testDirectorySelection(
      'picker errors retain the location and allow another attempt',
      (tester) async {
    picker.fails = true;
    await mount(tester);
    await select(tester);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), temp.path);
    expect(
        find.text('Failed to change the download location. Please try again'),
        findsOneWidget);
    picker.fails = false;
    await select(tester);
    expect(picker.calls, 2);
  });

  testDirectorySelection(
      'desktop directory selection does not request Android access',
      (tester) async {
    await mount(tester);
    await select(tester);
    expect(permissionCalls, 0);
    expect(picker.calls, 1);
  }, platforms: {
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  });

  testDirectorySelection(
      'unsupported platforms retain the location without opening the picker',
      (tester) async {
    await mount(tester);
    expect(find.byIcon(Icons.drive_file_move_outline), findsNothing);
    await select(tester);
    expect(permissionCalls, 0);
    expect(picker.calls, 0);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), temp.path);
    expect(find.text('This device does not support custom download locations'),
        findsOneWidget);
  }, platforms: {TargetPlatform.fuchsia});

  testDirectorySelection(
      'iOS uses its bookmark picker and saves a verified folder',
      (tester) async {
    picker.selected = '/provider/AnimeFlow';
    await mount(tester);
    expect(find.byIcon(Icons.drive_file_move_outline), findsOneWidget);
    await select(tester);
    expect(nativePickerCalls, 1);
    expect(permissionCalls, 0);
    expect(picker.calls, 0);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), picker.selected);
    expect(find.text(picker.selected!), findsOneWidget);
  }, platforms: {TargetPlatform.iOS});

  testDirectorySelection('iOS cancellation retains the download location',
      (tester) async {
    await mount(tester);
    await select(tester);
    expect(nativePickerCalls, 1);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), temp.path);
  }, platforms: {TargetPlatform.iOS});

  testDirectorySelection('iOS rejects a provider folder that is not writable',
      (tester) async {
    picker.selected = '/provider/read_only';
    writable = false;
    await mount(tester);
    await select(tester);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), temp.path);
    expect(
        find.text(
            'Cannot write to the selected folder. Choose another download location'),
        findsOneWidget);
  }, platforms: {TargetPlatform.iOS});
}
