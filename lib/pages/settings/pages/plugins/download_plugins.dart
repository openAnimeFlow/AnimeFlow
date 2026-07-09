import 'dart:convert';

import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/network/api_path.dart';
import 'package:anime_flow/network/requests/request.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:anime_flow/widget/animation_network_image.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DownloadPluginsPage extends StatefulWidget {
  const DownloadPluginsPage({super.key});

  @override
  State<DownloadPluginsPage> createState() => _DownloadPluginsPageState();
}

class _DownloadPluginsPageState extends State<DownloadPluginsPage> {
  final storage = Storage.crawlConfigs;
  final setting = Storage.setting;
  bool isLoading = false;
  late bool isMirror;
  String? errorMessage;

  // List<CrawlConfigItem>? plugins;
  List<dynamic>? pluginRepo;
  bool hasChanged = false; // 跟踪是否有插件被下载或更新

  /// 正在下载或更新中的插件名
  final Set<String> _busyPluginNames = {};

  @override
  void initState() {
    super.initState();
    isMirror = setting.get(SettingKey.isMirror, defaultValue: false);
    _getPlugins();
  }

  void _getPlugins() async {
    if (!isLoading && mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }
    try {
      String url = '${CommonApi.pluginRepo}/index.json';
      if (isMirror) url = Utils.jsDelivrCdnUrl(url);
      final data = await Request.getResources(url);
      final plugins = data is String
          ? jsonDecode(data) as List<dynamic>
          : data as List<dynamic>;
      if (mounted) {
        setState(() {
          isLoading = false;
          pluginRepo = plugins;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
      LiggLogger().e(e);
    }
  }

  void _persistPlugin(
    String pluginName,
    CrawlConfigItem pluginData,
    String catalogVersion,
  ) {
    final data = pluginData.toJson();
    data['version'] = catalogVersion;
    storage.put(pluginName, data);
  }

  Future<void> _downloadPlugin(Map<dynamic, dynamic> plugin) async {
    final pluginName = plugin['name'] as String;
    if (_busyPluginNames.contains(pluginName)) return;

    setState(() {
      _busyPluginNames.add(pluginName);
    });
    try {
      final pluginPath = plugin['path'] as String;
      var downloadUrl = '${CommonApi.pluginRepo}/$pluginPath';
      if (isMirror) downloadUrl = Utils.jsDelivrCdnUrl(downloadUrl);
      final raw = await Request.getResources(downloadUrl);
      final jsonMap = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      final pluginData = CrawlConfigItem.fromJson(jsonMap);
      final catalogVersion = plugin['version'] as String;
      _persistPlugin(pluginName, pluginData, catalogVersion);
      if (!mounted) return;
      setState(() {
        hasChanged = true;
      });
      NotificationToast.show('下载成功', '插件 "$pluginName" 已下载');
    } catch (e) {
      NotificationToast.show('下载失败', '下载插件 "$pluginName" 时发生错误：$e');
    } finally {
      if (mounted) {
        setState(() {
          _busyPluginNames.remove(pluginName);
        });
      }
    }
  }

  Future<void> _updatePlugin(
    Map<dynamic, dynamic> plugin,
    String pluginName,
    String pluginVersion,
  ) async {
    if (_busyPluginNames.contains(pluginName)) return;

    setState(() {
      _busyPluginNames.add(pluginName);
    });
    try {
      final pluginPath = plugin['path'] as String;
      var downloadUrl = '${CommonApi.pluginRepo}/$pluginPath';
      if (isMirror) downloadUrl = Utils.jsDelivrCdnUrl(downloadUrl);
      final raw = await Request.getResources(downloadUrl);
      final jsonMap = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      final pluginData = CrawlConfigItem.fromJson(jsonMap);
      _persistPlugin(pluginName, pluginData, pluginVersion);
      if (!mounted) return;
      setState(() {
        hasChanged = true;
      });
      NotificationToast.show(
        '更新成功',
        '插件 "$pluginName" 已更新到版本 $pluginVersion',
      );
    } catch (e) {
      NotificationToast.show(
        '更新失败',
        '更新插件 "$pluginName" 时发生错误：$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyPluginNames.remove(pluginName);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !hasChanged, // 如果有变化，不允许默认返回
      onPopInvokedWithResult: (didPop, result) {
        // 如果被调用但没有弹出（因为我们阻止了），手动调用返回并传递结果
        if (hasChanged && !didPop) {
          context.pop(true);
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
              trailing: SystemUtil.isDesktop
                  ? IconButton(
                      onPressed: () {
                        _getPlugins();
                      },
                      icon: const Icon(Icons.refresh),
                    )
                  : null,
            ),
            SwitchListTile(
              title: const Text('使用镜像'),
              subtitle: const Text('无法直连 GitHub 时开启，通过镜像拉取插件列表'),
              value: isMirror,
              onChanged: (v) {
                setState(() {
                  setting.put(SettingKey.isMirror, v);
                  isMirror = v;
                });
                _getPlugins();
              },
            ),
            if (isLoading)
              const Center(
                child: ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text('加载中...'),
                ),
              ),
            if (errorMessage != null && errorMessage!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.error, color: colorScheme.error),
                title: Text(
                  errorMessage!,
                  style: TextStyle(color: colorScheme.error),
                ),
              )
            else if (pluginRepo == null && !isLoading)
              const ListTile(
                title: Text('没有找到数据请刷新'),
              )
            else if (pluginRepo != null && !isLoading)
              ...pluginRepo!.map((plugin) {
                final pluginName = plugin['name'] as String;
                final localPlugin = storage.get(pluginName);
                final isPluginBusy = _busyPluginNames.contains(pluginName);
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
                                            pluginName,
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
                              onPressed: isPluginBusy
                                  ? null
                                  : () => _downloadPlugin(plugin),
                              icon: isPluginBusy
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.download))
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
                                onPressed: isPluginBusy
                                    ? null
                                    : () => _updatePlugin(
                                          plugin,
                                          pluginName,
                                          pluginVersion,
                                        ),
                                child: isPluginBusy
                                    ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text('更新中…'),
                                        ],
                                      )
                                    : const Text('更新'),
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
