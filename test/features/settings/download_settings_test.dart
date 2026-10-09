import 'dart:io';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/localization/app_localizations_delegates.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/settings/presentation/pages/download_settings.dart';
import 'package:anime_flow/features/download/presentation/providers/download_provider.dart';
import 'package:path/path.dart' as p;
import 'package:bot_toast/bot_toast.dart';
import 'package:file_picker/file_picker.dart';
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
  const macChannel = MethodChannel('anime_flow/download_directory');
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory temp;
  late _DirectoryPicker picker;
  var granted = true;
  var permissionCalls = 0;
  var storageCalls = 0;
  var macPickerCalls = 0;
  var bookmarkCalls = 0;
  var bookmarkFails = false;

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
    storageCalls = 0;
    macPickerCalls = 0;
    bookmarkCalls = 0;
    bookmarkFails = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(macChannel, (call) async {
      switch (call.method) {
        case 'restoreAccess':
          return (call.arguments as Map)['path'];
        case 'selectDirectory':
          macPickerCalls++;
          if (picker.fails) throw PlatformException(code: 'picker_failed');
          return picker.selected;
        case 'persistAccess':
          bookmarkCalls++;
          final directory = (call.arguments as Map)['path'] as String;
          // Verification has finished and its temporary files are gone.
          expect(Directory(directory).listSync(), isEmpty);
          if (bookmarkFails) throw PlatformException(code: 'bookmark_failed');
          return null;
        default:
          throw MissingPluginException(call.method);
      }
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (call) async {
      if (call.method == 'getApplicationSupportDirectory') return temp.path;
      throw MissingPluginException(call.method);
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      storageCalls++;
      if (call.method == 'hasDirectoryAccess') return granted;
      if (call.method == 'requestAccess') {
        permissionCalls++;
        return granted;
      }
      throw MissingPluginException(call.method);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(macChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
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
    TargetPlatform.linux,
  });

  testDirectorySelection(
      'macOS persists native picker access after verification', (tester) async {
    final target = Directory(p.join(temp.path, 'mac-selected'))..createSync();
    picker.selected = target.path;
    await mount(tester);
    await select(tester);
    expect(macPickerCalls, 1);
    expect(bookmarkCalls, 1);
    expect(permissionCalls, 0);
    expect(picker.calls, 0);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), target.path);
  }, platforms: {TargetPlatform.macOS});

  testDirectorySelection('macOS bookmark failure keeps the previous setting',
      (tester) async {
    final target = Directory(p.join(temp.path, 'mac-failure'))..createSync();
    picker.selected = target.path;
    bookmarkFails = true;
    await mount(tester);
    await select(tester);
    expect(bookmarkCalls, 1);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), temp.path);
    expect(
        find.text('Failed to change the download location. Please try again'),
        findsOneWidget);
    bookmarkFails = false;
    await select(tester);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), target.path);
  }, platforms: {TargetPlatform.macOS});

  testDirectorySelection('macOS cancellation does not persist a bookmark',
      (tester) async {
    await mount(tester);
    await select(tester);
    expect(macPickerCalls, 1);
    expect(bookmarkCalls, 0);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), temp.path);
  }, platforms: {TargetPlatform.macOS});

  testDirectorySelection('macOS rejects unwritable paths before bookmarking',
      (tester) async {
    final file = File(p.join(temp.path, 'mac-not-directory'))
      ..writeAsStringSync('keep');
    picker.selected = file.path;
    await mount(tester);
    await select(tester);
    expect(bookmarkCalls, 0);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), temp.path);
    expect(file.readAsStringSync(), 'keep');
  }, platforms: {TargetPlatform.macOS});

  testDirectorySelection(
      'fixed-directory platforms ignore saved custom paths and disable selection',
      (tester) async {
    await mount(tester);
    final defaultDirectory = p.join(temp.path, 'downloads');
    expect(find.byIcon(Icons.drive_file_move_outline), findsNothing);
    expect(find.text(defaultDirectory), findsOneWidget);
    expect(tester.widget<ListTile>(locationTile()).onTap, isNull);
    await tester.tap(locationTile());
    await tester.pumpAndSettle();
    expect(storageCalls, 0);
    expect(picker.calls, 0);
    expect(Storage.setting.get(DownloadKey.downloadDirectory), temp.path);
    expect(await tester.runAsync(getConfiguredDownloadDirectory),
        defaultDirectory);
    expect(tester.takeException(), isNull);
  }, platforms: {TargetPlatform.iOS, TargetPlatform.fuchsia});
}
