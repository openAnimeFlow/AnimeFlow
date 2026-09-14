import 'dart:async';

import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // 空格键：暂停/播放
          if (event.logicalKey == LogicalKeyboardKey.space) {
            playSession.playOrPauseVideo();
            videoUiNotifier.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.playStatusIndicator);
            return KeyEventResult.handled;
          }
          // 左方向键：快退10秒
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
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
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
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
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            videoUiNotifier
                .updateMainAxisAlignmentType(MainAxisAlignment.start);
            videoUiNotifier.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.volumeIndicator);
            playSession.adjustVolumeByWheel(5.0); // 每次增加5%
            return KeyEventResult.handled;
          }
          // 下方向键：减少音量
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            videoUiNotifier
                .updateMainAxisAlignmentType(MainAxisAlignment.start);
            videoUiNotifier.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.volumeIndicator);
            playSession.adjustVolumeByWheel(-5.0); // 每次减少5%
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Listener(
        // 鼠标指针信号事件监听（用于鼠标滚轮）
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            videoUiNotifier
                .updateMainAxisAlignmentType(MainAxisAlignment.start);
            videoUiNotifier.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.volumeIndicator);

            // 处理鼠标滚轮事件：调整音量
            // 向上滚动增加音量，向下滚动减少音量
            // 除以20是为了控制调整幅度（每次约5%）
            var scrollDelta = -event.scrollDelta.dy / 20;
            playSession.adjustVolumeByWheel(scrollDelta);
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
