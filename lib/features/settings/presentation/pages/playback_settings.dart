import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/shared/widgets/adaptive_app_bar.dart';
import 'package:anime_flow/features/settings/presentation/widgets/settings_page_builder.dart';
import 'package:anime_flow/features/play/presentation/extensions/player_kernel_localization.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

class PlaybackSettingsPage extends ConsumerStatefulWidget {
  const PlaybackSettingsPage({super.key});

  @override
  ConsumerState<PlaybackSettingsPage> createState() =>
      _PlaybackSettingsPageState();
}

class _PlaybackSettingsPageState extends ConsumerState<PlaybackSettingsPage> {
  // 播放配置状态
  late bool _autoPlayNext;
  late bool _episodesProgress;
  late bool _showMiniProgressBar;
  late double _fastForwardSpeed;
  late bool _adBlocker;
  late bool _hardwareDecoder;
  late int _skipDuration;
  late PlayerKernel _preferredPlayerKernel;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _autoPlayNext = AppSettings.autoPlayNext;
      _episodesProgress = AppSettings.episodesProgress;
      _showMiniProgressBar = AppSettings.showMiniProgressBar;
      _fastForwardSpeed = AppSettings.fastForwardSpeed;
      _adBlocker = AppSettings.adBlocker;
      _hardwareDecoder = AppSettings.hardwareDecoder;
      _skipDuration = AppSettings.skipDuration;
      _preferredPlayerKernel = _readPreferredPlayerKernel();
    });
  }

  PlayerKernel _readPreferredPlayerKernel() {
    final storedKernel = AppSettings.preferredPlayerKernelName;
    return ref.read(playbackPlatformProvider).availableKernels.firstWhere(
          (kernel) => kernel.name == storedKernel,
          orElse: () => PlayerKernel.mediaKit,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final padding = MediaQuery.paddingOf(context);
    final theme = Theme.of(context);
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      child: SettingsPageBuilder(
        builder: (context, glassStyle) => Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          extendBodyBehindAppBar: glassStyle,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Consumer(
              builder: (context, ref, _) => AdaptiveAppBar(
                glassStyle: glassStyle,
                title: Text(l10n.playbackSettings),
                automaticallyImplyLeading: !ref.watch(settingsLayoutProvider),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              10,
              SettingsPageBuilder.topInsetOf(context),
              10 + padding.right,
              16 + padding.bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    _buildSection(l10n.playbackSettings, [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.autoNextEpisode),
                        subtitle: Text(l10n.autoNextEpisodeSubtitle),
                        value: _autoPlayNext,
                        onChanged: (value) {
                          setState(() {
                            _autoPlayNext = value;
                            AppSettings.setAutoPlayNext(_autoPlayNext);
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.adBlocker),
                        subtitle: Text(l10n.adBlockerSubtitle),
                        value: _adBlocker,
                        onChanged: (value) {
                          setState(() {
                            _adBlocker = value;
                            AppSettings.setAdBlocker(_adBlocker);
                          });
                        },
                      ),
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.skipDuration,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  l10n.skipDurationSubtitle,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: TextEditingController(
                                text: _skipDuration.toString(),
                              ),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.all(5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixText: l10n.seconds,
                              ),
                              onChanged: (value) {
                                final parsed = int.tryParse(value);
                                if (parsed != null && parsed > 0) {
                                  setState(() {
                                    _skipDuration = parsed;
                                    AppSettings.setSkipDuration(_skipDuration);
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ]),
                    _buildSection(l10n.playbackProgress, [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.saveEpisodeProgress),
                        subtitle: Text(l10n.saveEpisodeProgressSubtitle),
                        value: _episodesProgress,
                        onChanged: (value) {
                          setState(() {
                            _episodesProgress = value;
                            AppSettings.setEpisodesProgress(_episodesProgress);
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.showMiniProgressBar),
                        subtitle: Text(l10n.showMiniProgressBarSubtitle),
                        value: _showMiniProgressBar,
                        onChanged: (value) {
                          setState(() {
                            _showMiniProgressBar = value;
                            AppSettings.setShowMiniProgressBar(value);
                          });
                        },
                      ),
                    ]),
                    _buildSection(l10n.playerKernel, [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.hardwareDecoding),
                        value: _hardwareDecoder,
                        onChanged: (value) {
                          setState(() {
                            _hardwareDecoder = value;
                            AppSettings.setHardwareDecoder(value);
                          });
                        },
                      ),
                      Row(
                        spacing: 5,
                        children: [
                          Expanded(
                            child: Text(
                              l10n.playerKernelTroubleshootingHint,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          _buildPlayerKernelMenu(l10n),
                        ],
                      ),
                    ]),
                    _buildSection(l10n.playbackControl, [
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: Text(
                              l10n.longPressFastForwardSpeed,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          Text(
                            '${_fastForwardSpeed.toStringAsFixed(1)}x',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(trackHeight: 15),
                        child: Slider(
                          value: _fastForwardSpeed,
                          min: 1.0,
                          max: 5.0,
                          divisions: 16,
                          label: '${_fastForwardSpeed.toStringAsFixed(1)}x',
                          onChanged: (value) {
                            setState(() {
                              _fastForwardSpeed = value;
                              AppSettings.setFastForwardSpeed(
                                  _fastForwardSpeed);
                            });
                          },
                        ),
                      ),
                      DefaultTextStyle.merge(
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text('1.0x'), Text('5.0x')],
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerKernelMenu(AppLocalizations l10n) {
    final kernels = ref.read(playbackPlatformProvider).availableKernels;
    return JellyMenu<PlayerKernel>(
      tooltip: l10n.selectPlayerKernel,
      triggerResizeDuration: const Duration(milliseconds: 220),
      triggerBuilder: (context, open) => TextButton(
        onPressed: open,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.kernelLabel(_preferredPlayerKernel)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      menuBuilder: (context, select) => SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final kernel in kernels)
                MenuItemButton(
                  trailingIcon: kernel == _preferredPlayerKernel
                      ? const Icon(Icons.check, size: 18)
                      : null,
                  onPressed: kernel == _preferredPlayerKernel
                      ? null
                      : () => select(kernel),
                  child: Text(l10n.kernelLabel(kernel)),
                ),
            ],
          ),
        ),
      ),
      onSelected: (kernel) {
        setState(() => _preferredPlayerKernel = kernel);
        AppSettings.setPreferredPlayerKernel(kernel.name);
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}
