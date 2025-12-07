import 'package:anime_flow/controllers/crawler/crawler_config_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class CategoryView extends StatefulWidget {
  const CategoryView({super.key});

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  late CrawlerConfigController crawlerConfigController;
  Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    crawlerConfigController = Get.put(CrawlerConfigController());
  }

  @override
  void dispose() {
    super.dispose();
    Get.delete<CrawlerConfigController>();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: OutlinedButton(
            onPressed: () async {
              final crawlerConfig =
                  await crawlerConfigController.loadAllCrawlConfigs();
              logger.i(crawlerConfig);
            },
            child: Text("查看全部配置")));
  }
}
