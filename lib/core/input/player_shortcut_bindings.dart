import 'package:anime_flow/shared/models/player/player_shortcut_action.dart';
import 'package:flutter/services.dart';

class PlayerShortcutBinding {
  const PlayerShortcutBinding.keyboard(this.key) : wheelDelta = null;
  const PlayerShortcutBinding.wheel(this.wheelDelta) : key = null;
  final LogicalKeyboardKey? key;
  final double? wheelDelta;
  bool get isWheel => wheelDelta != null;
  int get id => key?.keyId ?? (wheelDelta! > 0 ? -1 : -2);
}

extension PlayerShortcutDefaults on PlayerShortcutAction {
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
}
