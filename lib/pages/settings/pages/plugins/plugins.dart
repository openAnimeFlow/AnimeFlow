import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/controllers/setting_controller.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';

class PluginsPage extends StatefulWidget {
  const PluginsPage({super.key});

  @override
  State<PluginsPage> createState() => _PluginsPageState();
}

class _PluginsPageState extends State<PluginsPage> {
  late SettingController settingController;
  List<CrawlConfigItem> dataSources = [];
  final settingConfig = Storage.crawlConfigs;

  @override
  void initState() {
    super.initState();
    settingController = Get.find<SettingController>();
    settingConfig.listenable().addListener(_initData);
    _initData();
  }

  @override
  void deactivate() {
    settingConfig.listenable().removeListener(_initData);
    super.deactivate();
  }

  void _initData() async {
    final dataSources = await CrawlConfig.loadAllCrawlConfigs();
    setState(() {
      this.dataSources = dataSources;
    });
  }

  void _deleteDataSource(String name) async {
    // 使用Get.dialog显示确认弹窗
    Get.defaultDialog(
      title: "确认删除",
      middleText: "确定要删除数据源 \"$name\" 吗？此操作不可恢复。",
      textConfirm: "删除",
      textCancel: "取消",
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      buttonColor: Theme.of(context).colorScheme.error,
      onConfirm: () async {
        try {
          await settingConfig.delete(name);
          Get.back();
          Get.snackbar(
            "删除成功",
            "数据源 \"$name\" 已被删除",
            maxWidth: 300,
          );
        } catch (e) {
          Get.back();
          Get.snackbar(
            "删除失败",
            "删除数据源 \"$name\" 时发生错误：$e",
            maxWidth: 300,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: const Text('数据源管理'),
          automaticallyImplyLeading: !settingController.isWideScreen.value,
          actions: [
            //云下载
            IconButton(
                onPressed: ()  {
                   Get.toNamed(RouteName.settingDownloadPlugins);
                },
                icon: const Icon(Icons.cloud_download_outlined, size: 30)),
            IconButton(
              icon: const Icon(
                Icons.save_as_outlined,
                size: 30,
              ),
              onPressed: ()  {
                 Get.toNamed(RouteName.settingAddPlugins);
              },
            )
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: List.generate(dataSources.length, (index) {
            final data = dataSources[index];
            return InkWell(
              onTap: () =>
                Get.toNamed(
                  RouteName.settingAddPlugins,
                  arguments: data.name,
                ),
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 5),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
                        _deleteDataSource(data.name);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
