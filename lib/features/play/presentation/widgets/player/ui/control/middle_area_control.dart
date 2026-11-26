import 'dart:ui' show ImageFilter;

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/features/play/presentation/extensions/playback_notice_presentation.dart';
import 'package:anime_flow/features/play/presentation/providers/player_cache_speed_provider.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/core/utils/format_time_util.dart';
import 'package:anime_flow/core/utils/playback_format.dart';
import 'package:anime_flow/features/play/presentation/widgets/play_pause_icon.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

/// 播放器指示器
@Dependencies([VideoUiNotifier, PlayStateNotifier, playerCacheSpeed])
class MiddleAreaControl extends ConsumerWidget {
  const MiddleAreaControl({super.key});

  /// 顶部提示与顶部控件栏之间保留的间距。
  static const double _topIndicatorSpacing = 50.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 居中：播放错误、解析、缓冲、拖动进度
        Align(
          alignment: Alignment.center,
          child: _CenterIndicator(
            type: ref.watch(
              videoUiProvider.select((state) => state.centerIndicator),
            ),
          ),
        ),
        // 顶部：音量、亮度、播放状态、倍速
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: _topIndicatorSpacing),
            child: _TopIndicator(
              type: ref.watch(
                videoUiProvider.select((state) => state.topIndicator),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 居中指示器：播放错误、解析、缓冲与拖动进度
@Dependencies([VideoUiNotifier, PlayStateNotifier, playerCacheSpeed])
class _CenterIndicator extends ConsumerWidget {
  const _CenterIndicator({required this.type});

  final VideoControlsIndicatorType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const textStyle = TextStyle(
      shadows: [
        Shadow(color: Colors.black, offset: Offset(0, 0), blurRadius: 3)
      ],
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    final (phase, notice) = ref.watch(
      playStateProvider.select((state) => (state.phase, state.notice)),
    );
    if (phase == PlaybackPhase.error && notice != PlaybackNotice.none) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Semantics(
          liveRegion: true,
          child: Text(
            notice.localize(AppLocalizations.of(context)),
            textAlign: TextAlign.center,
            style: textStyle,
          ),
        ),
      );
    }

    return switch (type) {
      VideoControlsIndicatorType.bufferingIndicator => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 5,
            ),
            const SizedBox(height: 8),
            Row(mainAxisSize: MainAxisSize.min, spacing: 5, children: [
              Consumer(builder: (context, ref, child) {
                final speed = ref.watch(playerCacheSpeedProvider);
                // 重建或切换内核时不展示上一次采样的值。
                final value = speed.isLoading ? null : speed.asData?.value;
                if (value == null) return const SizedBox.shrink();
                return Text(formatBytesPerSec(value), style: textStyle);
              }),
              Text(AppLocalizations.of(context).buffering, style: textStyle),
            ]),
          ],
        ),
      VideoControlsIndicatorType.horizontalDraggingIndicator => Consumer(
          builder: (context, ref, child) {
            final dragPosition = ref.watch(
              videoUiProvider.select((state) => state.dragPosition),
            );
            final duration =
                ref.watch(playStateProvider.select((state) => state.duration));
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${FormatTimeUtil.formatDuration(dragPosition)} / ${FormatTimeUtil.formatDuration(duration)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      VideoControlsIndicatorType.parsingIndicator => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 5),
            Text(
              notice.localize(AppLocalizations.of(context)),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// 顶部提示：音量、亮度、播放状态与倍速，可与其他指示器同时展示。
@Dependencies([PlayStateNotifier, VideoUiNotifier])
class _TopIndicator extends ConsumerWidget {
  const _TopIndicator({required this.type});

  final VideoControlsIndicatorType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (type) {
      // 音量
      VideoControlsIndicatorType.volumeIndicator => Consumer(
          builder: (context, ref, child) {
            final volume =
                ref.watch(playStateProvider.select((state) => state.volume));
            return _ProgressCard(
              progress: volume / 100,
              icon: volume == 0
                  ? Icons.volume_off
                  : volume < 50
                      ? Icons.volume_down
                      : Icons.volume_up,
            );
          },
        ),
      // 亮度
      VideoControlsIndicatorType.brightnessIndicator => Consumer(
          builder: (context, ref, child) {
            final brightness = ref.watch(
              videoUiProvider.select((state) => state.currentBrightness),
            );
            return _ProgressCard(
              progress: brightness,
              icon: brightness < 0.3
                  ? Icons.brightness_2
                  : brightness < 0.7
                      ? Icons.brightness_4
                      : Icons.brightness_high,
            );
          },
        ),
      VideoControlsIndicatorType.playStatusIndicator => Container(
          height: 50,
          width: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Consumer(builder: (context, ref, child) {
            final playing =
                ref.watch(playStateProvider.select((state) => state.playing));
            return PlayPauseIcon(
              playing: playing,
              iconSize: 33,
              iconColor: Colors.white54,
            );
          }),
        ),
      VideoControlsIndicatorType.speedIndicator => Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              SvgPicture.asset(
                AssetsPathConstants.blockGroveFastForward,
                width: 30,
                height: 30,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              Consumer(builder: (context, ref, child) {
                final rate =
                    ref.watch(playStateProvider.select((state) => state.rate));
                return Text(
                  '${rate.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '')}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
            ],
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.icon,
  });

  final double progress;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    return Container(
      width: 180,
      height: 35,
      decoration: BoxDecoration(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: progress, end: progress),
                duration: const Duration(milliseconds: 80),
                builder: (context, value, child) => LinearProgressIndicator(
                  value: value,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                    right: Radius.circular(8),
                  ),
                  trackGap: 0,
                  stopIndicatorRadius: 0,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            Positioned(
              child: Padding(
                padding: const EdgeInsets.symmetric( horizontal: 5),
                child: Icon(icon, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
