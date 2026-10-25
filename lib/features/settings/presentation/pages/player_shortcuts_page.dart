import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/core/settings/player_shortcut_settings.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([settingsLayout])
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
        entry.key != action &&
        entry.key != PlayerShortcutAction.longPressFastForward &&
        action != PlayerShortcutAction.longPressFastForward &&
        entry.value.any((bound) => bound.id == key.id));
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
        entry.key != PlayerShortcutAction.longPressFastForward &&
        action != PlayerShortcutAction.longPressFastForward &&
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

  Future<void> _editSeekSeconds(PlayerShortcutAction action) async {
    setState(() => _capturing = null);
    final backward = action == PlayerShortcutAction.seekBackward;
    final l10n = AppLocalizations.of(context);
    final seconds = await showDialog<int>(
      context: context,
      builder: (_) => _SeekDurationDialog(
        title: backward
            ? l10n.playerShortcutSeekBackward
            : l10n.playerShortcutSeekForward,
        initialSeconds: backward
            ? AppSettings.shortcutSeekBackwardSeconds
            : AppSettings.shortcutSeekForwardSeconds,
      ),
    );
    if (seconds == null || !mounted) return;
    try {
      if (backward) {
        await AppSettings.setShortcutSeekBackwardSeconds(seconds);
      } else {
        await AppSettings.setShortcutSeekForwardSeconds(seconds);
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) NotificationToast.show(l10n.saveFailed, title: l10n.error);
    }
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
      PlayerShortcutAction.exitFullscreen: l10n.exitFullscreen,
      PlayerShortcutAction.screenshot: l10n.playerShortcutScreenshot,
      PlayerShortcutAction.toggleDanmaku: l10n.playerShortcutToggleDanmaku,
      PlayerShortcutAction.nextEpisode: l10n.nextEpisode,
      PlayerShortcutAction.longPressFastForward:
          l10n.playerShortcutLongPressFastForward,
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
                        durationEditor: switch (action) {
                          PlayerShortcutAction.seekBackward ||
                          PlayerShortcutAction.seekForward =>
                            ActionChip(
                              key: ValueKey('seek-seconds-${action.name}'),
                              label: Text(l10n.playerShortcutSeekSeconds(
                                action == PlayerShortcutAction.seekBackward
                                    ? AppSettings.shortcutSeekBackwardSeconds
                                    : AppSettings.shortcutSeekForwardSeconds,
                              )),
                              onPressed: () => _editSeekSeconds(action),
                            ),
                          _ => null,
                        },
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
      required this.onDelete,
      this.durationEditor});

  final List<PlayerShortcutBinding> keys;
  final String Function(PlayerShortcutBinding) keyLabel;
  final bool capturing;
  final String captureLabel;
  final String title;
  final VoidCallback onTap;
  final ValueChanged<PlayerShortcutBinding> onDelete;
  final Widget? durationEditor;

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
            if (durationEditor != null) durationEditor!,
          ],
        ),
      );
}

class _SeekDurationDialog extends StatefulWidget {
  const _SeekDurationDialog(
      {required this.title, required this.initialSeconds});

  final String title;
  final int initialSeconds;

  @override
  State<_SeekDurationDialog> createState() => _SeekDurationDialogState();
}

class _SeekDurationDialogState extends State<_SeekDurationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialSeconds.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(int.parse(_controller.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            suffixText: l10n.seconds,
            helperMaxLines: 2,
            errorMaxLines: 2,
            helperText: l10n.playerShortcutSeekSecondsRange(
                AppSettings.minShortcutSeekSeconds,
                AppSettings.maxShortcutSeekSeconds),
          ),
          validator: (text) {
            final seconds = int.tryParse(text ?? '');
            if (seconds == null ||
                seconds < AppSettings.minShortcutSeekSeconds ||
                seconds > AppSettings.maxShortcutSeekSeconds) {
              return l10n.playerShortcutSeekSecondsRange(
                  AppSettings.minShortcutSeekSeconds,
                  AppSettings.maxShortcutSeekSeconds);
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel)),
        TextButton(onPressed: _submit, child: Text(l10n.confirm)),
      ],
    );
  }
}
