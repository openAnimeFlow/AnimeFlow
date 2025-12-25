import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/pages/settings/setting_controller.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';

class DataSourcePage extends StatefulWidget {
  const DataSourcePage({super.key});

  @override
  State<DataSourcePage> createState() => _DataSourcePageState();
}

class _DataSourcePageState extends State<DataSourcePage> {
  late SettingController settingController;
  List<CrawlConfigItem> dataSources = [];

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

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: Text('数据源管理'),
          automaticallyImplyLeading: !settingController.isWideScreen.value,
          actions: [
            IconButton(
              icon: Icon(
                Icons.save_as_outlined,
                size: 30,
              ),
              onPressed: () {
                Navigator.of(context).pushNamed(RouteName.settingAddSource);
              },
            )
          ],
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16),
          children: List.generate(dataSources.length, (index) {
            final data = dataSources[index];
            return InkWell(
              onTap: () {
                print(data.name);
              },
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 2),
                padding: EdgeInsets.symmetric(vertical: 5),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _initData();
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
