import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:flutter/services.dart';

enum PlayerShortcutAction {
  playPause,
  seekBackward,
  seekForward,
  volumeUp,
  volumeDown,
  enterFullscreen,
  exitFullscreen,
  screenshot,
  toggleDanmaku,
  nextEpisode,
  longPressFastForward
}

class PlayerShortcutBinding {
  const PlayerShortcutBinding.keyboard(this.key) : wheelDelta = null;
  const PlayerShortcutBinding.wheel(this.wheelDelta) : key = null;
  final LogicalKeyboardKey? key;
  final double? wheelDelta;
  bool get isWheel => wheelDelta != null;
  int get id => key?.keyId ?? (wheelDelta! > 0 ? -1 : -2);
}

extension PlayerShortcutActionDetails on PlayerShortcutAction {
  String get storageKey => switch (this) {
        PlayerShortcutAction.playPause => PlayerShortcutKey.playPause,
        PlayerShortcutAction.seekBackward => PlayerShortcutKey.seekBackward,
        PlayerShortcutAction.seekForward => PlayerShortcutKey.seekForward,
        PlayerShortcutAction.volumeUp => PlayerShortcutKey.volumeUp,
        PlayerShortcutAction.volumeDown => PlayerShortcutKey.volumeDown,
        PlayerShortcutAction.enterFullscreen =>
          PlayerShortcutKey.enterFullscreen,
        PlayerShortcutAction.exitFullscreen => PlayerShortcutKey.exitFullscreen,
        PlayerShortcutAction.screenshot => PlayerShortcutKey.screenshot,
        PlayerShortcutAction.toggleDanmaku => PlayerShortcutKey.toggleDanmaku,
        PlayerShortcutAction.nextEpisode => PlayerShortcutKey.nextEpisode,
        PlayerShortcutAction.longPressFastForward =>
          PlayerShortcutKey.longPressFastForward,
      };

  List<PlayerShortcutBinding> get defaultBindings => switch (this) {
        PlayerShortcutAction.playPause => [
            const PlayerShortcutBinding.keyboard(LogicalKeyboardKey.space)
          ],
        PlayerShortcutAction.seekBackward => [
            const PlayerShortcutBinding.keyboard(LogicalKeyboardKey.arrowLeft)
          ],
        PlayerShortcutAction.seekForward => [
            const PlayerShortcutBinding.keyboard(LogicalKeyboardKey.arrowRight)
          ],
        PlayerShortcutAction.volumeUp => [
            const PlayerShortcutBinding.keyboard(LogicalKeyboardKey.arrowUp),
            const PlayerShortcutBinding.wheel(5)
          ],
        PlayerShortcutAction.volumeDown => [
            const PlayerShortcutBinding.keyboard(LogicalKeyboardKey.arrowDown),
            const PlayerShortcutBinding.wheel(-5)
          ],
        PlayerShortcutAction.enterFullscreen => [
            const PlayerShortcutBinding.keyboard(LogicalKeyboardKey.keyF)
          ],
        PlayerShortcutAction.exitFullscreen => [
            const PlayerShortcutBinding.keyboard(LogicalKeyboardKey.escape)
          ],
        PlayerShortcutAction.screenshot => [
            const PlayerShortcutBinding.keyboard(LogicalKeyboardKey.keyS)
          ],
        PlayerShortcutAction.toggleDanmaku => [
            const PlayerShortcutBinding.keyboard(LogicalKeyboardKey.keyD)
          ],
        PlayerShortcutAction.nextEpisode => [
            const PlayerShortcutBinding.keyboard(LogicalKeyboardKey.keyN)
          ],
        PlayerShortcutAction.longPressFastForward => [
            const PlayerShortcutBinding.keyboard(LogicalKeyboardKey.arrowRight)
          ],
      };

  List<PlayerShortcutBinding> readBindings() {
    final stored = Storage.setting.get(storageKey);
    final ids = stored is List
        ? stored.whereType<num>().map((id) => id.toInt()).toList()
        : stored is num
            ? [stored.toInt()]
            : defaultBindings.map((binding) => binding.id).toList();
    final bindings =
        ids.map(_bindingFromId).whereType<PlayerShortcutBinding>().toList();
    return bindings.isEmpty ? defaultBindings : bindings;
  }

  void saveBindings(List<PlayerShortcutBinding> bindings) => Storage.setting
      .put(storageKey, bindings.map((binding) => binding.id).toList());

  static PlayerShortcutBinding? _bindingFromId(int id) {
    if (id == -1) return const PlayerShortcutBinding.wheel(5);
    if (id == -2) return const PlayerShortcutBinding.wheel(-5);
    final key = LogicalKeyboardKey.findKeyByKeyId(id);
    return key == null ? null : PlayerShortcutBinding.keyboard(key);
  }
}
