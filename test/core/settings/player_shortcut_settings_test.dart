import 'dart:io';

import 'package:anime_flow/core/settings/player_shortcut_settings.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/storage_key.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory directory;
  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('player-shortcuts-');
    Storage.setting =
        await Hive.openBox<dynamic>('settings', path: directory.path);
  });
  tearDown(() => Storage.setting.clear());
  tearDownAll(() async {
    await Storage.setting.close();
    directory.deleteSync(recursive: true);
  });

  test(
      'reads legacy single keys and mixed lists, falling back for unusable values',
      () async {
    const action = PlayerShortcutAction.volumeUp;
    await Storage.setting.put(action.storageKey, LogicalKeyboardKey.keyA.keyId);
    expect(action.readBindings().single.key, LogicalKeyboardKey.keyA);
    await Storage.setting.put(action.storageKey, [
      LogicalKeyboardKey.space.keyId.toDouble(),
      -1,
      -2,
      'invalid',
      0x7ffffffff,
    ]);
    expect(action.readBindings().map((binding) => binding.id),
        [LogicalKeyboardKey.space.keyId, -1, -2]);
    await Storage.setting.put(action.storageKey, ['invalid', 0x7ffffffff]);
    expect(action.readBindings().map((binding) => binding.id),
        [LogicalKeyboardKey.arrowUp.keyId, -1]);
  });

  test('persists keyboard and wheel bindings with the existing storage format',
      () async {
    const action = PlayerShortcutAction.seekForward;
    await action.saveBindings([
      const PlayerShortcutBinding.keyboard(LogicalKeyboardKey.keyB),
      const PlayerShortcutBinding.wheel(-5),
    ]);
    expect(Storage.setting.get(action.storageKey),
        [LogicalKeyboardKey.keyB.keyId, -2]);
    final restored = action.readBindings();
    expect(restored.first.key, LogicalKeyboardKey.keyB);
    expect(restored.last.wheelDelta, -5);
  });

  test('speed shortcuts have distinct defaults and persist custom bindings',
      () async {
    expect(PlayerShortcutAction.speedUp.readBindings().single.key,
        LogicalKeyboardKey.bracketRight);
    expect(PlayerShortcutAction.speedDown.readBindings().single.key,
        LogicalKeyboardKey.bracketLeft);
    expect(PlayerShortcutAction.resetSpeed.readBindings().single.key,
        LogicalKeyboardKey.backslash);
    await PlayerShortcutAction.speedUp.saveBindings([
      const PlayerShortcutBinding.keyboard(LogicalKeyboardKey.keyB),
    ]);
    expect(PlayerShortcutAction.speedUp.readBindings().single.key,
        LogicalKeyboardKey.keyB);
    expect(PlayerShortcutAction.seekForward.readBindings().single.key,
        LogicalKeyboardKey.arrowRight);
  });

  test('speed step persists and rejects corrupt or unsupported settings',
      () async {
    expect(AppSettings.shortcutSpeedStep, 0.25);
    for (final step in AppSettings.shortcutSpeedSteps) {
      await AppSettings.setShortcutSpeedStep(step);
      expect(AppSettings.shortcutSpeedStep, step);
      expect(Storage.setting.get(PlayerShortcutKey.speedStep), step);
    }
    for (final invalid in [0, -1, 5, double.nan, double.infinity, '0.25']) {
      await Storage.setting.put(PlayerShortcutKey.speedStep, invalid);
      expect(AppSettings.shortcutSpeedStep, 0.25);
    }
    expect(() => AppSettings.setShortcutSpeedStep(0), throwsArgumentError);
  });
}
