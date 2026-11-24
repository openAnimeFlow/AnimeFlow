import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/presentation/providers/play_session_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/button/rate_button.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/button/upscale_button.dart';
import 'package:anime_flow/features/play/presentation/widgets/dialog/danmaku_setting_dialog.dart';
import 'package:anime_flow/features/play/presentation/widgets/player_settings_sheet.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/control/video_settings_menu.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

enum _PlayerMenuPage { main, rate, upscale, videoSettings }

@Dependencies([playSession, PlayStateNotifier, VideoUiNotifier])
class PlayerMoreButton extends ConsumerStatefulWidget {
  const PlayerMoreButton({super.key});

  @override
  ConsumerState<PlayerMoreButton> createState() => _PlayerMoreButtonState();
}

class _PlayerMoreButtonState extends ConsumerState<PlayerMoreButton> {
  _PlayerMenuPage _page = _PlayerMenuPage.main;

  void _showPage(_PlayerMenuPage page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = ref.read(playSessionProvider);
    final controls = ref.read(videoUiProvider.notifier);
    final rate = ref.watch(playStateProvider.select((state) => state.rate));
    final upscalePreset = ref.watch(
      playStateProvider.select((state) => state.upscalePreset),
    );

    ref.watch(playStateProvider.select((state) => state.kernel));
    final capabilities = player.playbackCoordinator.capabilities;

    @Dependencies([VideoUiNotifier])
    void openSettings(String label, Widget child) => showPlayerSettingsSheet(
          context: context,
          label: label,
          child: child,
          onOpen: controls.cancelUiTimer,
          onClose: controls.restartControlsAutoHideTimer,
        );

    return JellyMenu<VoidCallback>(
      tooltip: l10n.moreMenu,
      triggerColor: Colors.transparent,
      preferredVerticalDirection: VerticalDirection.down,
      trigger: const SizedBox.square(
        dimension: 48,
        child: Icon(Icons.more_vert, color: Colors.white),
      ),
      onOpenChanged: (isOpen) {
        if (isOpen) {
          controls.cancelUiTimer();
          if (_page != _PlayerMenuPage.main) _showPage(_PlayerMenuPage.main);
        } else {
          controls.hideControlsUi(duration: const Duration(seconds: 3));
        }
      },
      onSelected: (action) => action(),
      menuBuilder: (menuContext, select) {
        final items = switch (_page) {
          _PlayerMenuPage.main => [
              MenuItemButton(
                leadingIcon: const Icon(Icons.subtitles_outlined),
                onPressed: () => select(() => openSettings(
                      l10n.danmakuSettings,
                      const DanmakuSettingDialog(),
                    )),
                child: Text(l10n.danmakuSettings),
              ),
              MenuItemButton(
                closeOnActivate: false,
                leadingIcon: const Icon(Icons.settings_outlined),
                trailingIcon: const Icon(Icons.chevron_right),
                onPressed: () => _showPage(_PlayerMenuPage.videoSettings),
                child: Text(l10n.videoSettingsTitle),
              ),
              MenuItemButton(
                closeOnActivate: false,
                leadingIcon: const Icon(Icons.speed),
                trailingIcon: const Icon(Icons.chevron_right),
                onPressed: () => _showPage(_PlayerMenuPage.rate),
                child: Text('${l10n.playbackRate} · ${rate}x'),
              ),
              MenuItemButton(
                closeOnActivate: false,
                leadingIcon: const Icon(Icons.four_k_outlined),
                trailingIcon: const Icon(Icons.chevron_right),
                onPressed: () => _showPage(_PlayerMenuPage.upscale),
                child: const Text('4K'),
              ),
            ],
          _PlayerMenuPage.rate => [
              for (final speed in RateButton.speeds)
                MenuItemButton(
                  trailingIcon: rate == speed ? const Icon(Icons.check) : null,
                  onPressed: () => select(() => player.setPlaybackRate(speed)),
                  child: Text('${speed}x'),
                ),
            ],
          _PlayerMenuPage.upscale => buildUpscaleMenuItems(
              context,
              value: upscalePreset,
              capabilities: capabilities,
              onChanged: player.setUpscalePreset,
              onActivate: select,
            ),
          _PlayerMenuPage.videoSettings => const <Widget>[],
        };

        return AnimatedSize(
          alignment: Alignment.topCenter,
          duration: MediaQuery.disableAnimationsOf(menuContext)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: _page == _PlayerMenuPage.videoSettings
              ? VideoSettingsMenu(
                  onBack: () => _showPage(_PlayerMenuPage.main),
                  onSelect: select,
                )
              : SingleChildScrollView(
                  key: ValueKey(_page),
                  primary: false,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 168),
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_page != _PlayerMenuPage.main)
                            MenuItemButton(
                              closeOnActivate: false,
                              leadingIcon: const BackButtonIcon(),
                              onPressed: () => _showPage(_PlayerMenuPage.main),
                              child: Text(l10n.back),
                            ),
                          ...items,
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
