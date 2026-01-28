import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/requests/request.dart';
import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/controllers/setting_controller.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class DownloadPluginsPage extends StatefulWidget {
  const DownloadPluginsPage({super.key});

  @override
  State<DownloadPluginsPage> createState() => _DownloadPluginsPageState();
}

class _DownloadPluginsPageState extends State<DownloadPluginsPage> {
  late SettingController settingController;
  final storage = Storage.crawlConfigs;
  bool isLoading = false;

  // List<CrawlConfigItem>? plugins;
  List<dynamic>? pluginRepo;
  bool hasChanged = false; // 跟踪是否有插件被下载或更新

  @override
  void initState() {
    super.initState();
    settingController = Get.find<SettingController>();
    _getPlugins();
  }

  void _getPlugins() async {
    if (!isLoading && mounted) {
      setState(() {
        isLoading = true;
      });
    }
    try {
      final plugins = await Request.getPluginRepo();
      Get.log('获取$plugins');
      if (mounted) {
        setState(() {
          isLoading = false;
          pluginRepo = plugins;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      Logger().e(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasChanged, // 如果有变化，不允许默认返回
      onPopInvokedWithResult: (didPop, result) {
        // 如果被调用但没有弹出（因为我们阻止了），手动调用返回并传递结果
        if (hasChanged && !didPop) {
          Get.back(result: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('下载配置'),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            _getPlugins();
          },
          child: ListView(padding: EdgeInsets.zero, children: [
            ListTile(
              title: const Text(
                '下载数据源',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('当前会从Github仓库中下载数据源，注意网络环境,下拉刷新数据'),
              trailing: Utils.isDesktop
                  ? IconButton(
                      onPressed: () {
                        _getPlugins();
                      },
                      icon: const Icon(Icons.refresh),
                    )
                  : null,
            ),
            if (isLoading)
              const Center(
                child: ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text('加载中...'),
                ),
              ),
            if (pluginRepo == null && !isLoading)
              const ListTile(
                title: Text('没有找到数据请刷新'),
              ),
            if (pluginRepo != null && !isLoading)
              ...pluginRepo!.map((plugin) {
                final localPlugin = storage.get(plugin['name']);
                return Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Card(
                    elevation: 0.2,
                    child: Row(
                      children: [
                        Expanded(
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                child: Row(
                                  children: [
                                    AnimationNetworkImage(
                                        height: 50,
                                        width: 50,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        url: plugin['icon']),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${plugin['name']}',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                              '版本:${plugin['version']} - ${FormatTimeUtil.formatUpdateTime(plugin['updateTime'])}'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ))),
                        if (localPlugin == null)
                          IconButton(
                              onPressed: () async {
                                try {
                                  final pluginName = plugin['name'] as String;
                                  final pluginPath = plugin['path'] as String;
                                  final downloadUrl =
                                      '${CommonApi.pluginRepo}/$pluginPath';
                                  final pluginData =
                                      await Request.getPlugin(downloadUrl);
                                  storage.put(pluginName, pluginData.toJson());
                                  if (mounted) {
                                    setState(() {
                                      hasChanged = true;
                                    });
                                  }
                                  Get.snackbar(
                                    '下载成功',
                                    '插件 "$pluginName" 已下载',
                                    snackPosition: SnackPosition.BOTTOM,
                                    maxWidth: 400,
                                  );
                                } catch (e) {
                                  Get.snackbar(
                                    '下载失败',
                                    '下载插件 "${plugin['name']}" 时发生错误：$e',
                                    snackPosition: SnackPosition.BOTTOM,
                                    maxWidth: 400,
                                  );
                                }
                              },
                              icon: const Icon(Icons.download))
                        else
                          Builder(builder: (context) {
                            final config = CrawlConfigItem.fromJson(
                              Map<String, dynamic>.from(localPlugin),
                            );
                            final pluginVersion = plugin['version'] as String;
                            final isNew = Utils.compareVersionNumbers(
                                pluginVersion, config.version);
                            if (isNew == 0 || isNew == -1) {
                              return TextButton(
                                onPressed: () {},
                                child: const Text('已下载'),
                              );
                            } else {
                              return TextButton(
                                onPressed: () async {
                                  try {
                                    final pluginName = plugin['name'] as String;
                                    final pluginPath = plugin['path'] as String;
                                    final downloadUrl =
                                        '${CommonApi.pluginRepo}/$pluginPath';
                                    final pluginData =
                                        await Request.getPlugin(downloadUrl);
                                    storage.put(
                                        pluginName, pluginData.toJson());
                                    if (mounted) {
                                      setState(() {
                                        hasChanged = true;
                                      });
                                    }
                                    Get.snackbar(
                                      '更新成功',
                                      '插件 "$pluginName" 已更新到版本 $pluginVersion',
                                      snackPosition: SnackPosition.BOTTOM,
                                      maxWidth: 400,
                                    );
                                  } catch (e) {
                                    Get.snackbar(
                                      '更新失败',
                                      '更新插件 "${plugin['name']}" 时发生错误：$e',
                                      snackPosition: SnackPosition.BOTTOM,
                                      maxWidth: 400,
                                    );
                                  }
                                },
                                child: const Text('更新'),
                              );
                            }
                          })
                      ],
                    ),
                  ),
                );
              }),
          ]),
        ),
      ),
    );
  }
}
