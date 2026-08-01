import 'dart:convert';

import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/api/api.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/core/utils/format_time_util.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

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
      final data = await Api.getResources(url);
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
    final l10n = AppLocalizations.of(context);
    final pluginName = plugin['name'] as String;
    if (_busyPluginNames.contains(pluginName)) return;

    setState(() {
      _busyPluginNames.add(pluginName);
    });
    try {
      final pluginPath = plugin['path'] as String;
      var downloadUrl = '${CommonApi.pluginRepo}/$pluginPath';
      if (isMirror) downloadUrl = Utils.jsDelivrCdnUrl(downloadUrl);
      final raw = await Api.getResources(downloadUrl);
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
      NotificationToast.show(
          l10n.downloadSuccess, l10n.pluginDownloaded(pluginName));
    } catch (e) {
      NotificationToast.show(
        l10n.downloadFailed,
        l10n.pluginDownloadFailed(pluginName, e.toString()),
      );
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
    final l10n = AppLocalizations.of(context);
    if (_busyPluginNames.contains(pluginName)) return;

    setState(() {
      _busyPluginNames.add(pluginName);
    });
    try {
      final pluginPath = plugin['path'] as String;
      var downloadUrl = '${CommonApi.pluginRepo}/$pluginPath';
      if (isMirror) downloadUrl = Utils.jsDelivrCdnUrl(downloadUrl);
      final raw = await Api.getResources(downloadUrl);
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
        l10n.updateSuccess,
        l10n.pluginUpdated(pluginName, pluginVersion),
      );
    } catch (e) {
      NotificationToast.show(
        l10n.updateFailed,
        l10n.pluginUpdateFailed(pluginName, e.toString()),
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
    final l10n = AppLocalizations.of(context);
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
          title: Text(l10n.downloadConfig),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            _getPlugins();
          },
          child: ListView(padding: EdgeInsets.zero, children: [
            ListTile(
              title: Text(
                l10n.downloadSources,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(l10n.downloadSourcesSubtitle),
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
              title: Text(l10n.useMirror),
              subtitle: Text(l10n.useMirrorSubtitle),
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
              Center(
                child: ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text(l10n.loading),
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
              ListTile(
                title: Text(l10n.noDataRefresh),
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
                                          Text(l10n.pluginVersionDate(
                                            plugin['version'] as String,
                                            FormatTimeUtil.formatUpdateTime(
                                              plugin['updateTime'],
                                            ),
                                          )),
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
                                child: Text(l10n.downloaded),
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
                                    ? Row(
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
                                          Text(l10n.updating),
                                        ],
                                      )
                                    : Text(l10n.update),
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
