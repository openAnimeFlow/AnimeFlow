import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/core/network_speed/network_speed_provider.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/core/utils/format_time_util.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/features/play/presentation/widgets/play_pause_icon.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 播放器指示器
/// 顶部提示与居中指示器各自成层，可同时展示且互不影响。
class MiddleAreaControl extends ConsumerWidget {
  const MiddleAreaControl({super.key});

  /// 顶部提示与顶部控件栏之间保留的间距。
  static const double _topIndicatorSpacing = 50.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 居中：解析、缓冲、拖动进度
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

/// 居中指示器：解析、缓冲与拖动进度，可长期驻留。
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

    return switch (type) {
      VideoControlsIndicatorType.bufferingIndicator => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 5,
            ),
            const SizedBox(height: 8),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Consumer(builder: (context, ref, child) {
                final speed =
                    ref.watch(networkSpeedStreamProvider(2000)).asData?.value;
                return Text(
                  ' ${Utils.formatBytesPerSec(speed?.download ?? 0)}',
                  style: textStyle,
                );
              }),
              const SizedBox(width: 5),
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
            Consumer(builder: (context, ref, child) {
              final statusMessage = ref
                  .watch(playStateProvider.select((state) => state.statusMessage));
              return Text(
                statusMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            }),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// 顶部提示：音量、亮度、播放状态与倍速，可与其他指示器同时展示。
class _TopIndicator extends ConsumerWidget {
  const _TopIndicator({required this.type});

  final VideoControlsIndicatorType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (type) {
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
                  '${rate.toStringAsFixed(1)}x',
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

/// 音量与亮度共用的条形提示。
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.icon});

  final double progress;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned.fill(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white30,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Positioned(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
