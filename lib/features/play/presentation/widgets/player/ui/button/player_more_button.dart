import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/application/player_bindings.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/button/rate_button.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/button/shader_button.dart';
import 'package:anime_flow/features/play/presentation/widgets/dialog/danmaku_setting_dialog.dart';
import 'package:anime_flow/features/play/presentation/widgets/player_settings_sheet.dart';
import 'package:anime_flow/features/play/presentation/widgets/dialog/video_setting_dialog.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([playSession, PlayStateNotifier, VideoUiNotifier])
class PlayerMoreButton extends ConsumerWidget {
  const PlayerMoreButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final player = ref.read(playSessionProvider);
    final controls = ref.read(videoUiProvider.notifier);
    final rate = ref.watch(playStateProvider.select((state) => state.rate));
    final shader = ref.watch(
      playStateProvider.select((state) => state.superResolutionType),
    );

    return MenuAnchor(
      onOpen: controls.cancelUiTimer,
      onClose: controls.restartControlsAutoHideTimer,
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.subtitles_outlined),
          onPressed: () => showPlayerSettingsSheet(
            context: context,
            label: l10n.danmakuSettings,
            child: const DanmakuSettingDialog(),
            onOpen: controls.cancelUiTimer,
            onClose: controls.restartControlsAutoHideTimer,
          ),
          child: Text(l10n.danmakuSettings),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.settings_outlined),
          onPressed: () => showPlayerSettingsSheet(
            context: context,
            label: l10n.videoSettingsTitle,
            child: const VideoSettingDialog(),
            onOpen: controls.cancelUiTimer,
            onClose: controls.restartControlsAutoHideTimer,
          ),
          child: Text(l10n.videoSettingsTitle),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.speed),
          menuChildren: [
            for (final speed in RateButton.speeds)
              MenuItemButton(
                trailingIcon: rate == speed ? const Icon(Icons.check) : null,
                onPressed: () => player.setPlaybackRate(speed),
                child: Text('${speed}x'),
              ),
          ],
          child: Text('${l10n.playbackRate} · ${rate}x'),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.four_k_outlined),
          menuChildren: [
            for (var index = 0; index < ShaderButton.labels.length; index++)
              MenuItemButton(
                trailingIcon:
                    shader == index + 1 ? const Icon(Icons.check) : null,
                onPressed: () async {
                  try {
                    await player.setShader(index + 1);
                  } catch (error) {
                    if (!context.mounted) return;
                    NotificationToast.show(
                      error is UnsupportedError
                          ? error.message ?? error.toString()
                          : error.toString(),
                      title: l10n.tip,
                    );
                  }
                },
                child: Text(ShaderButton.labels[index]),
              ),
          ],
          child: const Text('4K'),
        ),
      ],
      builder: (context, controller, child) => IconButton(
        tooltip: l10n.moreMenu,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.more_vert, color: Colors.white),
      ),
    );
  }
}
