import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/pages/settings/setting_controller.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:anime_flow/utils/storage.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DataSourcePage extends StatefulWidget {
  const DataSourcePage({super.key});

  @override
  State<DataSourcePage> createState() => _DataSourcePageState();
}

class _DataSourcePageState extends State<DataSourcePage> {
  late SettingController settingController;
  List<CrawlConfigItem> dataSources = [];
  final settingConfig = Storage.crawlConfigs;
  @override
  void initState() {
    super.initState();
    settingController = Get.find<SettingController>();
    _initData();
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
          setState(() {
            _initData();
          });
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
            IconButton(
              icon: const Icon(
                Icons.save_as_outlined,
                size: 30,
              ),
              onPressed: () async {
                final result = await Get.toNamed(RouteName.settingAddSource);
                // 如果返回成功标志，刷新数据
                if (result == true) {
                  _initData();
                  Get.snackbar(
                    '保存成功',
                    '数据源已保存',
                    maxWidth: 400,
                  );
                }
              },
            )
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: List.generate(dataSources.length, (index) {
            final data = dataSources[index];
            return InkWell(
              onTap: () async {
                final result = await Get.toNamed(
                  RouteName.settingAddSource,
                  arguments: data.name,
                );
                // 如果返回成功标志，刷新数据
                if (result == true) {
                  _initData();
                  Get.snackbar(
                    '保存成功',
                    '数据源已保存',
                    maxWidth: 400,
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color:
                        Theme.of(context).disabledColor.withValues(alpha: 0.1)),
                child: ListTile(
                  leading: AnimationNetworkImage(
                    borderRadius: BorderRadius.circular(50),
                    width: 40,
                    height: 40,
                    url: data.iconUrl,
                  ),
                  title: Text(
                    data.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () {
                      _deleteDataSource(data.name);
                    },
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
