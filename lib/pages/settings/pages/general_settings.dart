import 'package:anime_flow/pages/settings/setting_provider.dart';
import 'package:anime_flow/pages/settings/widget/setting_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeneralSettingsPage extends ConsumerStatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  ConsumerState<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends ConsumerState<GeneralSettingsPage> {
  // 模拟设置状态（仅做展示 Demo，尚未实现真实本地化存储）
  bool autoSkipOpEd = true;
  bool autoPlayNext = true;
  bool hardwareAcceleration = true;
  bool enableDanmaku = true;
  String defaultQuality = '1080P';
  double danmakuOpacity = 0.8;

  @override
  Widget build(BuildContext context) {
    final leftMediaQueryPadding = MediaQuery.of(context).padding.left;
    final isWideScreen = ref.watch(settingsLayoutProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: const Text('通用设置'),
          automaticallyImplyLeading: !isWideScreen,
          centerTitle: true,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: EdgeInsets.only(
                left: leftMediaQueryPadding + 16,
                right: 16,
                top: 16,
                bottom: 32),
            children: [
              const SettingTitle(title: '播放习惯'),
              SettingCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: const Text('自动跳过片头片尾 (OP/ED)'),
                      subtitle: const Text('检测到OP/ED时自动跳过'),
                      value: autoSkipOpEd,
                      onChanged: (val) {
                        setState(() => autoSkipOpEd = val);
                      },
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: const Text('自动连播'),
                      subtitle: const Text('当前剧集播放完毕后自动播放下一集'),
                      value: autoPlayNext,
                      onChanged: (val) {
                        setState(() => autoPlayNext = val);
                      },
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: const Text('默认清晰度'),
                      subtitle: const Text('选择视频首选的播放画质'),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: defaultQuality,
                          items: ['4K', '1080P', '720P', '480P']
                              .map((q) => DropdownMenuItem(
                                    value: q,
                                    child: Text(q),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => defaultQuality = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const SettingTitle(title: '弹幕设置'),
              SettingCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: const Text('默认开启弹幕'),
                      subtitle: const Text('播放视频时自动加载并显示弹幕'),
                      value: enableDanmaku,
                      onChanged: (val) {
                        setState(() => enableDanmaku = val);
                      },
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: const Text('全局弹幕透明度'),
                      subtitle: Slider(
                        value: danmakuOpacity,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: '${(danmakuOpacity * 100).toInt()}%',
                        onChanged: (val) {
                          setState(() => danmakuOpacity = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const SettingTitle(title: '下载与缓存'),
              SettingCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: const Text('下载目录'),
                      subtitle: const Text('/home/waya/Videos/AnimeFlow'),
                      trailing: FilledButton.tonal(
                        onPressed: () {},
                        child: const Text('更改'),
                      ),
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: const Text('清除图片缓存'),
                      subtitle: const Text('释放应用占用的本地图片缓存空间（128 MB）'),
                      trailing: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('缓存已清理')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const SettingTitle(title: '高级'),
              SettingCard(
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: const Text('硬件加速'),
                  subtitle: const Text('开启硬件解码（若播放黑屏或卡顿请尝试关闭）'),
                  value: hardwareAcceleration,
                  onChanged: (val) {
                    setState(() => hardwareAcceleration = val);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
