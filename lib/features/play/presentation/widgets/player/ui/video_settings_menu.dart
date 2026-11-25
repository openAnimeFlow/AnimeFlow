import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/utils/format_time_util.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/presentation/extensions/player_kernel_localization.dart';
import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_session_provider.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

enum _SettingsPage { main, timer, kernel }

@Dependencies([playSession, PlayStateNotifier])
class VideoSettingsMenu extends ConsumerStatefulWidget {
  const VideoSettingsMenu({
    super.key,
    this.onBack,
    required this.onSelect,
  });

  final VoidCallback? onBack;
  final ValueChanged<VoidCallback> onSelect;

  @override
  ConsumerState<VideoSettingsMenu> createState() => _VideoSettingsMenuState();
}

class _VideoSettingsMenuState extends ConsumerState<VideoSettingsMenu> {
  _SettingsPage _page = _SettingsPage.main;
  bool _savingDecoder = false;

  void _showPage(_SettingsPage page) => setState(() => _page = page);

  Future<void> _setHardwareDecoder(bool enabled) async {
    final l10n = AppLocalizations.of(context);
    final player = ref.read(playSessionProvider);
    setState(() => _savingDecoder = true);
    try {
      final applied = await player.setHardwareDecoder(enabled);
      if (mounted && !applied) {
        NotificationToast.show(l10n.hardwareDecodingFailed);
      }
    } catch (_) {
      if (mounted) NotificationToast.show(l10n.hardwareDecodingFailed);
    } finally {
      if (mounted) setState(() => _savingDecoder = false);
    }
  }

  Future<void> _switchKernel(PlayerKernel target) async {
    final l10n = AppLocalizations.of(context);
    final switched = await ref.read(playSessionProvider).switchKernel(target);
    if (!mounted) return;
    if (switched) {
      if (_page == _SettingsPage.kernel) _showPage(_SettingsPage.main);
    } else {
      NotificationToast.show(l10n.playerKernelSwitchFailed);
    }
  }

  void _applyTimer(Duration duration) {
    final player = ref.read(playSessionProvider);
    widget.onSelect(() {
      if (duration == Duration.zero) {
        player.cancelScheduledStop();
      } else {
        player.stopPlaying(duration: duration);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (kernel, switching) = ref.watch(playStateProvider.select(
      (state) => (state.kernel, state.switchingKernel),
    ));
    final busy = switching || _savingDecoder;
    final onBack = _page == _SettingsPage.main
        ? widget.onBack
        : () => _showPage(_SettingsPage.main);
    final items = switch (_page) {
      _SettingsPage.main => [
          Consumer(builder: (context, ref, _) {
            final (canSchedule, remaining) = ref.watch(
              playStateProvider.select(
                (state) => (
                  state.position > Duration.zero,
                  state.scheduledStopDuration
                ),
              ),
            );
            if (!canSchedule && remaining == 0) {
              return const SizedBox.shrink();
            }
            return MenuItemButton(
              closeOnActivate: false,
              overflowAxis: Axis.vertical,
              leadingIcon: const Icon(Icons.timer_outlined),
              trailingIcon: const Icon(Icons.chevron_right),
              onPressed: () => _showPage(_SettingsPage.timer),
              child: Text(
                remaining == 0
                    ? l10n.scheduledOff
                    : '${l10n.scheduledOff} · ${FormatTimeUtil.formatDuration(Duration(seconds: remaining))}',
              ),
            );
          }),
          MenuItemButton(
            closeOnActivate: false,
            overflowAxis: Axis.vertical,
            leadingIcon: const Icon(Icons.video_settings_outlined),
            trailingIcon: busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onPressed: busy ? null : () => _showPage(_SettingsPage.kernel),
            child: Text('${l10n.playerKernel} · ${l10n.kernelLabel(kernel)}'),
          ),
          SwitchListTile(
            title: Text(l10n.hardwareDecoding),
            value: ref.read(playPreferencesProvider).hardwareDecoder,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            onChanged: busy || kernel == PlayerKernel.videoPlayer
                ? null
                : _setHardwareDecoder,
          ),
        ],
      _SettingsPage.timer => [_ScheduledStopPicker(onConfirm: _applyTimer)],
      _SettingsPage.kernel => [
          for (final option
              in ref.read(playbackPlatformProvider).availableKernels)
            MenuItemButton(
              closeOnActivate: false,
              overflowAxis: Axis.vertical,
              trailingIcon: option == kernel ? const Icon(Icons.check) : null,
              onPressed:
                  busy || option == kernel ? null : () => _switchKernel(option),
              child: Text(l10n.kernelLabel(option)),
            ),
        ],
    };
    return SizedBox(
      width: 256,
      child: PlayerMenuPageSwitcher(
        mainPageKey: const ValueKey(_SettingsPage.main),
        child: SingleChildScrollView(
          key: ValueKey(_page),
          primary: false,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (onBack != null)
                MenuItemButton(
                  closeOnActivate: false,
                  overflowAxis: Axis.vertical,
                  leadingIcon: const BackButtonIcon(),
                  onPressed: onBack,
                  child: Text(l10n.back),
                ),
              ...items,
            ],
          ),
        ),
      ),
    );
  }
}

class PlayerMenuPageSwitcher extends StatelessWidget {
  const PlayerMenuPageSwitcher({
    super.key,
    required this.mainPageKey,
    required this.child,
  });

  final LocalKey mainPageKey;
  final Widget child;

  static const duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    return ClipRect(
      child: AnimatedSwitcher(
        duration:
            MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic.flipped,
        transitionBuilder: (child, animation) => SlideTransition(
          textDirection: textDirection,
          position: Tween<Offset>(
            begin: Offset(child.key == mainPageKey ? -1 : 1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: Align(
            alignment: Alignment.topCenter,
            widthFactor: 1,
            heightFactor: 1,
            child: child,
          ),
        ),
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: [
            for (final child in previousChildren)
              _stackPage(child, outgoing: true),
            if (currentChild != null) _stackPage(currentChild, outgoing: false),
          ],
        ),
        child: child,
      ),
    );
  }

  static Widget _stackPage(Widget child, {required bool outgoing}) {
    // Keep outgoing pages mounted without contributing to the menu size.
    final inset = outgoing ? 0.0 : null;
    return Positioned.fill(
      key: child.key,
      left: inset,
      top: inset,
      right: inset,
      bottom: inset,
      child: IgnorePointer(
        ignoring: outgoing,
        child: ExcludeFocus(
          excluding: outgoing,
          child: ExcludeSemantics(excluding: outgoing, child: child),
        ),
      ),
    );
  }
}

class _ScheduledStopPicker extends StatefulWidget {
  const _ScheduledStopPicker({required this.onConfirm});

  final ValueChanged<Duration> onConfirm;

  @override
  State<_ScheduledStopPicker> createState() => _ScheduledStopPickerState();
}

class _ScheduledStopPickerState extends State<_ScheduledStopPicker> {
  final _hoursController = FixedExtentScrollController();
  final _minutesController = FixedExtentScrollController();
  int _hours = 0;
  int _minutes = 0;

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final durationLabel = switch ((_hours, _minutes)) {
      (0, 0) => l10n.close,
      (0, final minutes) => l10n.minutesUnit(minutes),
      (final hours, 0) => l10n.hoursUnit(hours),
      (final hours, final minutes) => l10n.hoursMinutesUnit(hours, minutes),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              children: [
                Expanded(
                  child: _buildWheel(
                    controller: _hoursController,
                    count: 24,
                    selected: _hours,
                    label: l10n.hoursUnit,
                    onChanged: (value) => setState(() => _hours = value),
                  ),
                ),
                Expanded(
                  child: _buildWheel(
                    controller: _minutesController,
                    count: 60,
                    selected: _minutes,
                    label: l10n.minutesUnit,
                    onChanged: (value) => setState(() => _minutes = value),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(child: Text(durationLabel)),
              TextButton(
                onPressed: () => widget.onConfirm(
                  Duration(hours: _hours, minutes: _minutes),
                ),
                child: Text(l10n.confirm),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int count,
    required int selected,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 40,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) => Center(
          child: Text(
            label(index),
            style: index == selected
                ? theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
