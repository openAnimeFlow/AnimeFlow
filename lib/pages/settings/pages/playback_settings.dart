import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/pages/settings/setting_provider.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _autoPlayNext = setting.get(PlaybackKey.autoPlayNext, defaultValue: true);
      _episodesProgress = setting.get(PlaybackKey.episodesProgress, defaultValue: true);
      _fastForwardSpeed = setting.get(PlaybackKey.fastForwardSpeed, defaultValue: 2.0);
      _adBlocker = setting.get(PlaybackKey.adBlocker, defaultValue: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer(
          builder: (context, ref, _) {
            final isWideScreen = ref.watch(settingsLayoutProvider);
            return AppBar(
              title: const Text('播放设置'),
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
                    _buildSectionTitle('播放设置'),
                    SwitchListTile(
                      title: const Text('自动跳转下一集'),
                      subtitle: const Text('播放完成后自动切换到下一集'),
                      value: _autoPlayNext,
                      onChanged: (value) {
                        setState(() {
                          _autoPlayNext = value;
                          setting.put(PlaybackKey.autoPlayNext, _autoPlayNext);
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('过滤广告'),
                      subtitle: const Text('过滤视频中插入的广告切片'),
                      value: _adBlocker,
                      onChanged: (value) {
                        setState(() {
                          _adBlocker = value;
                          setting.put(PlaybackKey.adBlocker, _adBlocker);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // 进度设置
                    _buildSectionTitle('播放进度'),
                    SwitchListTile(
                      title: const Text('保存剧集进度'),
                      subtitle: const Text('自动保存保存剧集进度,下次从未观看的剧集开始播放'),
                      value: _episodesProgress,
                      onChanged: (value) {
                        setState(() {
                          _episodesProgress = value;
                          setting.put(PlaybackKey.episodesProgress, _episodesProgress);
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 播放速度设置
                    _buildSectionTitle('播放控制'),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '长按快进速度',
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
                                setting.put(
                                    PlaybackKey.fastForwardSpeed, _fastForwardSpeed);
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
