import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/core/storage/storage.dart';
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
    });
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
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                l10n.skipDurationSubtitle,
                                style: TextStyle(fontSize: 12),
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
                              style: TextStyle(fontSize: 16),
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
}
