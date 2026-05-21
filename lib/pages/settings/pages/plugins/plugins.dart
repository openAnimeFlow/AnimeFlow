import 'package:anime_flow/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/pages/settings/setting_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/adapters.dart';

class PluginsPage extends StatefulWidget {
  const PluginsPage({super.key});

  @override
  State<PluginsPage> createState() => _PluginsPageState();
}

class _PluginsPageState extends State<PluginsPage> {
  List<CrawlConfigItem> dataSources = [];
  final settingConfig = Storage.crawlConfigs;

  @override
  void initState() {
    super.initState();
    settingConfig.listenable().addListener(initData);
    initData();
  }

  @override
  void deactivate() {
    settingConfig.listenable().removeListener(initData);
    super.deactivate();
  }

  void initData() async {
    final dataSources = await CrawlConfig.loadAllCrawlConfigs();
    setState(() {
      this.dataSources = dataSources;
    });
  }

  Future<void> deleteDataSource(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除数据源 "$name" 吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await settingConfig.delete(name);
      if (!mounted) return;
      NotificationToast.show('删除成功', '数据源 "$name" 已被删除');
    } catch (e) {
      NotificationToast.show('删除失败', '删除数据源 "$name" 时发生错误：$e');
    }
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
              title: const Text('数据源管理'),
              automaticallyImplyLeading: !isWideScreen,
              actions: [
                IconButton(
                  onPressed: () {
                    const SettingDownloadPluginsRoute().push(context);
                  },
                  icon: const Icon(Icons.cloud_download_outlined, size: 30),
                ),
                IconButton(
                  icon: const Icon(Icons.save_as_outlined, size: 30),
                  onPressed: () {
                    const SettingAddPluginsRoute().push(context);
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: List.generate(dataSources.length, (index) {
          final data = dataSources[index];
          return InkWell(
            onTap: () =>
                SettingAddPluginsRoute(editPluginKey: data.name).push(context),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color:
                      Theme.of(context).disabledColor.withValues(alpha: 0.1)),
              child: Row(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                    child: AnimationNetworkImage(
                        borderRadius: BorderRadius.circular(10),
                        width: 50,
                        height: 50,
                        url: data.iconUrl),
                  ),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(data.version)
                        ]),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () {
                      deleteDataSource(data.name);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
