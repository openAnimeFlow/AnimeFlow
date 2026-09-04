import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

class PlaybackSettingsPage extends StatefulWidget {
  const PlaybackSettingsPage({super.key});

  @override
  State<PlaybackSettingsPage> createState() => _PlaybackSettingsPageState();
}

class _PlaybackSettingsPageState extends State<PlaybackSettingsPage> {
  final setting = Storage.setting;

  // 播放配置状态
  late bool _autoPlayNext;
  late bool _episodesProgress;
  late double _fastForwardSpeed;
  late bool _adBlocker;
  late int _skipDuration;
  late PlayerKernel _preferredPlayerKernel;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _autoPlayNext = setting.get(PlaybackKey.autoPlayNext, defaultValue: true);
      _episodesProgress =
          setting.get(PlaybackKey.episodesProgress, defaultValue: true);
      _fastForwardSpeed =
          setting.get(PlaybackKey.fastForwardSpeed, defaultValue: 2.0);
      _adBlocker = setting.get(PlaybackKey.adBlocker, defaultValue: false);
      _skipDuration = setting.get(PlaybackKey.skipDuration, defaultValue: 85);
      _preferredPlayerKernel = _readPreferredPlayerKernel();
    });
  }

  PlayerKernel _readPreferredPlayerKernel() {
    final storedKernel = setting.get(
      PlaybackKey.preferredPlayerKernel,
      defaultValue: PlayerKernel.mediaKit.name,
    );
    return PlayerKernel.values.firstWhere(
      (kernel) => kernel.name == storedKernel,
      orElse: () => PlayerKernel.mediaKit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer(
          builder: (context, ref, _) {
            final isWideScreen = ref.watch(settingsLayoutProvider);
            return AppBar(
              title: Text(l10n.playbackSettings),
              automaticallyImplyLeading: !isWideScreen,
            );
          },
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 自动播放设置
                  _buildSectionTitle(l10n.playbackSettings),
                  SwitchListTile(
                    title: Text(l10n.autoNextEpisode),
                    subtitle: Text(l10n.autoNextEpisodeSubtitle),
                    value: _autoPlayNext,
                    onChanged: (value) {
                      setState(() {
                        _autoPlayNext = value;
                        setting.put(PlaybackKey.autoPlayNext, _autoPlayNext);
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text(l10n.adBlocker),
                    subtitle: Text(l10n.adBlockerSubtitle),
                    value: _adBlocker,
                    onChanged: (value) {
                      setState(() {
                        _adBlocker = value;
                        setting.put(PlaybackKey.adBlocker, _adBlocker);
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
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
                              )
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
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 5),
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
                                  setting.put(
                                      PlaybackKey.skipDuration, _skipDuration);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 进度设置
                  _buildSectionTitle(l10n.playbackProgress),
                  SwitchListTile(
                    title: Text(l10n.saveEpisodeProgress),
                    subtitle: Text(l10n.saveEpisodeProgressSubtitle),
                    value: _episodesProgress,
                    onChanged: (value) {
                      setState(() {
                        _episodesProgress = value;
                        setting.put(
                            PlaybackKey.episodesProgress, _episodesProgress);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 播放器内核设置
                  _buildSectionTitle(l10n.playerKernel),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      spacing: 5,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.playerKernelTroubleshootingHint,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        DropDownMenu<PlayerKernel>(
                          items: PlayerKernel.values,
                          selectedItem: _preferredPlayerKernel,
                          tooltip: l10n.selectPlayerKernel,
                          offset: const Offset(0, 44),
                          buttonBuilder: (context, selectedKernel) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_kernelLabel(
                                selectedKernel ?? _preferredPlayerKernel,
                              )),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                          itemBuilder: (context, kernel, isSelected) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_kernelLabel(kernel)),
                              if (isSelected) ...[
                                const SizedBox(width: 12),
                                const Icon(Icons.check, size: 18),
                              ],
                            ],
                          ),
                          onSelected: (kernel) {
                            setState(() {
                              _preferredPlayerKernel = kernel;
                              setting.put(
                                PlaybackKey.preferredPlayerKernel,
                                kernel.name,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _preferredPlayerKernel == PlayerKernel.mediaKit
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          size: 16,
                          color: _preferredPlayerKernel == PlayerKernel.mediaKit
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _preferredPlayerKernel == PlayerKernel.mediaKit
                                ? l10n.playerKernelSupportsSuperResolution
                                : l10n.playerKernelNoSuperResolution,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 播放速度设置
                  _buildSectionTitle(l10n.playbackControl),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.longPressFastForwardSpeed,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              '${_fastForwardSpeed.toStringAsFixed(1)}x',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 15,
                        ),
                        child: Slider(
                          value: _fastForwardSpeed,
                          min: 1.0,
                          max: 5.0,
                          divisions: 16,
                          label: '${_fastForwardSpeed.toStringAsFixed(1)}x',
                          onChanged: (value) {
                            setState(() {
                              _fastForwardSpeed = value;
                              setting.put(PlaybackKey.fastForwardSpeed,
                                  _fastForwardSpeed);
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '1.0x',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '5.0x',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _kernelLabel(PlayerKernel kernel) {
    return switch (kernel) {
      PlayerKernel.mediaKit => AppLocalizations.of(context).mediaKit,
      PlayerKernel.fvp => AppLocalizations.of(context).fvp,
    };
  }
}
