import 'package:anime_flow/features/play/application/player_bindings.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/gesture/desktop_gesture_detector.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/gesture/mobile_gesture_detector.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:material_ui/material_ui.dart';

import 'control/bottom_area_control.dart';
import 'control/middle_area_control.dart';
import 'control/right_area_control.dart';
import 'control/top_area_control.dart';
import 'screenshot_preview.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_state_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/subject_online_count_provider.dart';

/// 播放器 UI。
@Dependencies([
  playSession,
  PlayStateNotifier,
  VideoUiNotifier,
  VideoSourceNotifier,
  Episodes,
  playExtra,
  AnimeInfo,
  subjectOnlineCount,
  DanmakuStateNotifier
])
class VideoUi extends StatelessWidget {
  const VideoUi({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = SystemUtil.isMobile;
    return Stack(
      children: [
        /// 控件事件
        Positioned.fill(
          child: isMobile
              ? const MobileGestureDetector(child: MiddleAreaControl())
              : const DesktopGestureDetector(child: MiddleAreaControl()),
        ),

        ///顶部
        const Positioned(top: 0, left: 0, right: 0, child: TopAreaControl()),

        ///底部
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: BottomAreaControl(),
        ),

        ///右侧
        const Positioned(
            right: 0, top: 0, bottom: 0, child: RightAreaControl()),

        ///截图缩略图
        const ScreenshotPreviewOverlay(),
      ],
    );
  }
}
