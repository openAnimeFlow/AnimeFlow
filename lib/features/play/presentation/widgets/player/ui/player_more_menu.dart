import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/presentation/providers/play_session_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/button/rate_button.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/button/upscale_button.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/video_settings_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

enum _PlayerMenuPage { main, rate, upscale, videoSettings }

@Dependencies([playSession, PlayStateNotifier])
class PlayerMoreMenu extends ConsumerStatefulWidget {
  const PlayerMoreMenu({
    super.key,
    required this.onSelect,
    required this.onOpenDanmakuSettings,
  });

  final ValueChanged<VoidCallback> onSelect;
  final VoidCallback onOpenDanmakuSettings;

  @override
  ConsumerState<PlayerMoreMenu> createState() => _PlayerMoreMenuState();
}

class _PlayerMoreMenuState extends ConsumerState<PlayerMoreMenu> {
  _PlayerMenuPage _page = _PlayerMenuPage.main;

  void _showPage(_PlayerMenuPage page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = ref.read(playSessionProvider);
    final rate = ref.watch(playStateProvider.select((state) => state.rate));
    final upscalePreset = ref.watch(
      playStateProvider.select((state) => state.upscalePreset),
    );

    ref.watch(playStateProvider.select((state) => state.kernel));
    final capabilities = player.playbackCoordinator.capabilities;

    final items = switch (_page) {
      _PlayerMenuPage.main => [
          MenuItemButton(
            leadingIcon: const Icon(Icons.subtitles_outlined),
            onPressed: () => widget.onSelect(widget.onOpenDanmakuSettings),
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
              onPressed: () =>
                  widget.onSelect(() => player.setPlaybackRate(speed)),
              child: Text('${speed}x'),
            ),
        ],
      _PlayerMenuPage.upscale => buildUpscaleMenuItems(
          context,
          value: upscalePreset,
          capabilities: capabilities,
          onChanged: player.setUpscalePreset,
          onActivate: widget.onSelect,
        ),
      _PlayerMenuPage.videoSettings => const <Widget>[],
    };

    return AnimatedSize(
      alignment: Alignment.topCenter,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : PlayerMenuPageSwitcher.duration,
      curve: Curves.easeOutCubic,
      child: PlayerMenuPageSwitcher(
        mainPageKey: const ValueKey(_PlayerMenuPage.main),
        child: _page == _PlayerMenuPage.videoSettings
            ? VideoSettingsMenu(
                key: const ValueKey(_PlayerMenuPage.videoSettings),
                onBack: () => _showPage(_PlayerMenuPage.main),
                onSelect: widget.onSelect,
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
      ),
    );
  }
}
