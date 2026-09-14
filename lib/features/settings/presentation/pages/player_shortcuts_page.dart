import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/features/play/domain/player/player_shortcut.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerShortcutsPage extends ConsumerStatefulWidget {
  const PlayerShortcutsPage({super.key});

  @override
  ConsumerState<PlayerShortcutsPage> createState() =>
      _PlayerShortcutsPageState();
}

class _PlayerShortcutsPageState extends ConsumerState<PlayerShortcutsPage> {
  final _focusNode = FocusNode(debugLabel: 'Player shortcut editor');
  PlayerShortcutAction? _capturing;
  late Map<PlayerShortcutAction, List<PlayerShortcutBinding>> _keys;

  @override
  void initState() {
    super.initState();
    _keys = {
      for (final action in PlayerShortcutAction.values)
        action: action.readBindings()
    };
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _keyLabel(PlayerShortcutBinding binding) {
    if (binding.isWheel) return binding.wheelDelta! > 0 ? 'Wheel ↑' : 'Wheel ↓';
    final key = binding.key!;
    return switch (key) {
      LogicalKeyboardKey.space => 'Space',
      LogicalKeyboardKey.arrowLeft => '←',
      LogicalKeyboardKey.arrowRight => '→',
      LogicalKeyboardKey.arrowUp => '↑',
      LogicalKeyboardKey.arrowDown => '↓',
      _ => key.keyLabel.isNotEmpty ? key.keyLabel : key.debugName ?? 'Unknown',
    };
  }

  void _capture(KeyEvent event) {
    final action = _capturing;
    if (action == null || event is! KeyDownEvent) return;
    final key = PlayerShortcutBinding.keyboard(event.logicalKey);
    final conflict = _keys.entries.any((entry) =>
        entry.key != action && entry.value.any((bound) => bound.id == key.id));
    final duplicate = _keys[action]!.any((bound) => bound.id == key.id);
    if (conflict || duplicate) {
      NotificationToast.show(
          AppLocalizations.of(context).playerShortcutConflict,
          title: AppLocalizations.of(context).error);
    } else {
      setState(() {
        _keys[action]!.add(key);
        _capturing = null;
      });
      action.saveBindings(_keys[action]!);
    }
    return;
  }

  void _captureWheel(PointerScrollEvent event) {
    final action = _capturing;
    if (action == null || event.scrollDelta.dy == 0) return;
    final binding =
        PlayerShortcutBinding.wheel(event.scrollDelta.dy < 0 ? 5 : -5);
    final conflict = _keys.entries.any((entry) =>
        entry.key != action &&
        entry.value.any((bound) => bound.id == binding.id));
    final duplicate = _keys[action]!.any((bound) => bound.id == binding.id);
    if (conflict || duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).playerShortcutConflict)));
      return;
    }
    setState(() {
      _keys[action]!.add(binding);
      _capturing = null;
    });
    action.saveBindings(_keys[action]!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isWideScreen = ref.watch(settingsLayoutProvider);
    final titles = {
      PlayerShortcutAction.playPause: l10n.playerShortcutPlayPause,
      PlayerShortcutAction.seekBackward: l10n.playerShortcutSeekBackward,
      PlayerShortcutAction.seekForward: l10n.playerShortcutSeekForward,
      PlayerShortcutAction.volumeUp: l10n.playerShortcutVolumeUp,
      PlayerShortcutAction.volumeDown: l10n.playerShortcutVolumeDown,
      PlayerShortcutAction.enterFullscreen: l10n.playerShortcutEnterFullscreen,
      PlayerShortcutAction.exitFullscreen: l10n.playerShortcutExitFullscreen,
      PlayerShortcutAction.screenshot: l10n.playerShortcutScreenshot,
      PlayerShortcutAction.toggleDanmaku: l10n.playerShortcutToggleDanmaku,
      PlayerShortcutAction.nextEpisode: l10n.playerShortcutNextEpisode,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.playerShortcuts),
        automaticallyImplyLeading: !isWideScreen,
      ),
      body: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent && _capturing != null) {
            _captureWheel(event);
          }
        },
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: (node, event) {
            final wasCapturing = _capturing != null;
            _capture(event);
            return wasCapturing
                ? KeyEventResult.handled
                : KeyEventResult.ignored;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.playerShortcutsDescription),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final action in PlayerShortcutAction.values) ...[
                      _ShortcutTile(
                        keys: _keys[action]!,
                        keyLabel: _keyLabel,
                        capturing: _capturing == action,
                        captureLabel: l10n.playerShortcutPressKey,
                        title: titles[action]!,
                        onDelete: (key) => setState(() {
                          _keys[action]!.remove(key);
                          action.saveBindings(_keys[action]!);
                        }),
                        onTap: () => setState(() {
                          _capturing = action;
                          _focusNode.requestFocus();
                        }),
                      ),
                      if (action != PlayerShortcutAction.values.last)
                        const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile(
      {required this.keys,
      required this.keyLabel,
      required this.capturing,
      required this.captureLabel,
      required this.title,
      required this.onTap,
      required this.onDelete});

  final List<PlayerShortcutBinding> keys;
  final String Function(PlayerShortcutBinding) keyLabel;
  final bool capturing;
  final String captureLabel;
  final String title;
  final VoidCallback onTap;
  final ValueChanged<PlayerShortcutBinding> onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(title),
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final key in keys)
              InputChip(
                  label: Text(keyLabel(key)),
                  onDeleted: keys.length > 1 ? () => onDelete(key) : null),
            ActionChip(
                label: Text(capturing ? captureLabel : '+'), onPressed: onTap),
          ],
        ),
      );
}
