import 'dart:async';

import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/domain/player/player_shortcut.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 桌面端手势检测器
class DesktopGestureDetector extends ConsumerStatefulWidget {
  final Widget child;

  const DesktopGestureDetector({super.key, required this.child});

  @override
  ConsumerState<DesktopGestureDetector> createState() =>
      _DesktopGestureDetectorState();
}

class _DesktopGestureDetectorState
    extends ConsumerState<DesktopGestureDetector> {
  Timer? hoverTimer;
  final _focusNode = FocusNode(debugLabel: 'Desktop player');
  late final PlaySession playSession;
  late final VideoUiNotifier videoUiNotifier;

  @override
  void initState() {
    super.initState();
    playSession = ref.read(playSessionProvider);
    videoUiNotifier = ref.read(videoUiProvider.notifier);
  }

  @override
  void dispose() {
    hoverTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _takeScreenshot() async {
    final bytes = await playSession.takeScreenshot();
    if (bytes != null) {
      await SystemUtil.saveImageBytes(bytes, name: 'video_screenshot');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          final pressed = event.logicalKey.keyId;
          final shortcut = {
            for (final action in PlayerShortcutAction.values)
              action:
                  action.readBindings().map((binding) => binding.id).toSet(),
          };
          // 已绑定快捷键的重复事件也必须消费，避免方向键长按触发
          // Flutter 默认的焦点遍历；每次按下仍只执行一次播放器操作。
          if (event is KeyRepeatEvent) {
            return shortcut.values.any((bindings) => bindings.contains(pressed))
                ? KeyEventResult.handled
                : KeyEventResult.ignored;
          }
          // 空格键：暂停/播放
          if (shortcut[PlayerShortcutAction.playPause]!.contains(pressed)) {
            playSession.playOrPauseVideo();
            videoUiNotifier.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.playStatusIndicator);
            return KeyEventResult.handled;
          }
          // 左方向键：快退10秒
          if (shortcut[PlayerShortcutAction.seekBackward]!.contains(pressed)) {
            final playState = ref.read(playStateProvider);
            final currentPosition = playState.position;
            final duration = playState.duration;
            final newPositionMs =
                (currentPosition - const Duration(seconds: 10)).inMilliseconds;
            final clampedMs = newPositionMs.clamp(0, duration.inMilliseconds);
            playSession.seekTo(Duration(milliseconds: clampedMs));
            hoverTimer?.cancel();
            videoUiNotifier.showControlsUi();
            hoverTimer = Timer(const Duration(seconds: 3), () {
              videoUiNotifier.hideControlsUi();
            });
            return KeyEventResult.handled;
          }
          // 右方向键：快进10秒
          if (shortcut[PlayerShortcutAction.seekForward]!.contains(pressed)) {
            final playState = ref.read(playStateProvider);
            final currentPosition = playState.position;
            final duration = playState.duration;
            final newPositionMs =
                (currentPosition + const Duration(seconds: 10)).inMilliseconds;
            final clampedMs = newPositionMs.clamp(0, duration.inMilliseconds);
            playSession.seekTo(Duration(milliseconds: clampedMs));
            hoverTimer?.cancel();
            videoUiNotifier.showControlsUi();
            hoverTimer = Timer(const Duration(seconds: 3), () {
              videoUiNotifier.hideControlsUi();
            });
            return KeyEventResult.handled;
          }
          // 上方向键：增加音量
          if (shortcut[PlayerShortcutAction.volumeUp]!.contains(pressed)) {
            videoUiNotifier
                .updateMainAxisAlignmentType(MainAxisAlignment.start);
            videoUiNotifier.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.volumeIndicator);
            playSession.adjustVolumeByWheel(5.0); // 每次增加5%
            return KeyEventResult.handled;
          }
          // 下方向键：减少音量
          if (shortcut[PlayerShortcutAction.volumeDown]!.contains(pressed)) {
            videoUiNotifier
                .updateMainAxisAlignmentType(MainAxisAlignment.start);
            videoUiNotifier.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.volumeIndicator);
            playSession.adjustVolumeByWheel(-5.0); // 每次减少5%
            return KeyEventResult.handled;
          }
          if (shortcut[PlayerShortcutAction.enterFullscreen]!
              .contains(pressed)) {
            playSession.toggleFullScreen();
            return KeyEventResult.handled;
          }
          if (shortcut[PlayerShortcutAction.exitFullscreen]!
              .contains(pressed)) {
            playSession.exitFullScreen();
            return KeyEventResult.handled;
          }
          if (shortcut[PlayerShortcutAction.screenshot]!.contains(pressed)) {
            unawaited(_takeScreenshot());
            return KeyEventResult.handled;
          }
          if (shortcut[PlayerShortcutAction.toggleDanmaku]!.contains(pressed)) {
            playSession.toggleDanmaku();
            return KeyEventResult.handled;
          }
          if (shortcut[PlayerShortcutAction.nextEpisode]!.contains(pressed)) {
            playSession.switchToNextEpisode();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Listener(
        // 鼠标指针信号事件监听（用于鼠标滚轮）
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            final delta = event.scrollDelta.dy < 0 ? 5.0 : -5.0;
            final action = delta > 0
                ? PlayerShortcutAction.volumeUp
                : PlayerShortcutAction.volumeDown;
            if (!action.readBindings().any(
                (binding) => binding.isWheel && binding.wheelDelta == delta)) {
              return;
            }
            videoUiNotifier
                .updateMainAxisAlignmentType(MainAxisAlignment.start);
            videoUiNotifier.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.volumeIndicator);

            playSession.adjustVolumeByWheel(delta);
          }
        },
        child: MouseRegion(
          // 鼠标移入事件
          // onEnter: (event) {
          //   videoUiStateController.showControlsUi();
          // },

          // 鼠标悬停事件
          onHover: (event) {
            hoverTimer?.cancel();
            videoUiNotifier.showControlsUi();
            hoverTimer = Timer(const Duration(seconds: 3), () {
              videoUiNotifier.hideControlsUi();
            });
          },

          // 鼠标移出事件
          onExit: (event) {
            hoverTimer?.cancel();
            videoUiNotifier.hideControlsUi(
                duration: const Duration(seconds: 3));
          },

          child: GestureDetector(
            // 双击事件
            onDoubleTap: () {
              _focusNode.requestFocus();
              playSession.toggleFullScreen();
            },

            // 单击事件
            onTap: () {
              _focusNode.requestFocus();
              playSession.playOrPauseVideo();
              videoUiNotifier.updateIndicatorTypeAndShowIndicator(
                  VideoControlsIndicatorType.playStatusIndicator);
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
