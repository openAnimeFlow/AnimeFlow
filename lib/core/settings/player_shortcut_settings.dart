import 'package:anime_flow/core/settings/storage_key.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/input/player_shortcut_bindings.dart';
import 'package:anime_flow/shared/models/player/player_shortcut_action.dart';
import 'package:flutter/services.dart';

export 'package:anime_flow/core/input/player_shortcut_bindings.dart';
export 'package:anime_flow/shared/models/player/player_shortcut_action.dart';

extension PlayerShortcutActionDetails on PlayerShortcutAction {
  String get storageKey => switch (this) {
        PlayerShortcutAction.playPause => PlayerShortcutKey.playPause,
        PlayerShortcutAction.seekBackward => PlayerShortcutKey.seekBackward,
        PlayerShortcutAction.seekForward => PlayerShortcutKey.seekForward,
        PlayerShortcutAction.volumeUp => PlayerShortcutKey.volumeUp,
        PlayerShortcutAction.volumeDown => PlayerShortcutKey.volumeDown,
        PlayerShortcutAction.speedUp => PlayerShortcutKey.speedUp,
        PlayerShortcutAction.speedDown => PlayerShortcutKey.speedDown,
        PlayerShortcutAction.resetSpeed => PlayerShortcutKey.resetSpeed,
        PlayerShortcutAction.enterFullscreen =>
          PlayerShortcutKey.enterFullscreen,
        PlayerShortcutAction.exitFullscreen => PlayerShortcutKey.exitFullscreen,
        PlayerShortcutAction.screenshot => PlayerShortcutKey.screenshot,
        PlayerShortcutAction.toggleDanmaku => PlayerShortcutKey.toggleDanmaku,
        PlayerShortcutAction.nextEpisode => PlayerShortcutKey.nextEpisode,
        PlayerShortcutAction.longPressFastForward =>
          PlayerShortcutKey.longPressFastForward,
      };

  List<PlayerShortcutBinding> readBindings() {
    final stored = AppSettings.getSetting<Object?>(storageKey);
    final ids = stored is List
        ? stored.whereType<num>().map((id) => id.toInt()).toList()
        : stored is num
            ? [stored.toInt()]
            : defaultBindings.map((binding) => binding.id).toList();
    final bindings =
        ids.map(_bindingFromId).whereType<PlayerShortcutBinding>().toList();
    return bindings.isEmpty ? defaultBindings : bindings;
  }

  Future<void> saveBindings(List<PlayerShortcutBinding> bindings) =>
      AppSettings.setSetting(
          storageKey, bindings.map((binding) => binding.id).toList());

  static PlayerShortcutBinding? _bindingFromId(int id) {
    if (id == -1) return const PlayerShortcutBinding.wheel(5);
    if (id == -2) return const PlayerShortcutBinding.wheel(-5);
    final key = LogicalKeyboardKey.findKeyByKeyId(id);
    return key == null ? null : PlayerShortcutBinding.keyboard(key);
  }
}
