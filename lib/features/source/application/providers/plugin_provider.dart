import 'dart:convert';

import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/crawler/rule_api_level.dart';
import 'package:anime_flow/core/network/api/api.dart';
import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plugin_provider.g.dart';

class PluginCatalogItem {
  const PluginCatalogItem({
    required this.name,
    required this.path,
    required this.version,
    required this.icon,
    required this.updateTime,
    this.api,
  });

  factory PluginCatalogItem.fromJson(Map<String, dynamic> json) {
    return PluginCatalogItem(
      name: json['name'] as String,
      path: json['path'] as String,
      version: json['version'].toString(),
      icon: json['icon'] as String?,
      updateTime: json['updateTime'],
      api: json['api']?.toString(),
    );
  }

  final String name;
  final String path;
  final String version;
  final String? icon;
  final dynamic updateTime;

  /// 规则要求的客户端规则 API 级别。
  ///
  /// 目录未提供该字段时为 null，此时按兼容处理，真正的拦截在下载后由
  /// `SourceRepository` 依规则内容判断。
  final String? api;

  bool get requiresNewerClient => RuleApiLevel.requiresNewerClient(api);
}

bool _isPluginMirrorEnabled() {
  return AppSettings.getSetting<bool>(
        SettingKey.isMirror,
        defaultValue: false,
      ) ??
      false;
}

@riverpod
class PluginCatalog extends _$PluginCatalog {
  CancelToken? _cancelToken;

  @override
  Future<List<PluginCatalogItem>> build() {
    ref.onDispose(() {
      _cancelToken?.cancel('插件目录 Provider 已销毁');
    });
    return _fetch();
  }

  Future<List<PluginCatalogItem>> _fetch() async {
    _cancelToken?.cancel('插件目录请求已被新的请求替换');
    final cancelToken = _cancelToken = CancelToken();
    var url = '${CommonApi.pluginRepo}/index.json';
    if (_isPluginMirrorEnabled()) {
      url = Utils.jsDelivrCdnUrl(url);
    }

    final data = await Api.getResources(url, cancelToken: cancelToken);
    final json = data is String ? jsonDecode(data) : data;
    if (json is! List) {
      throw const FormatException('插件目录格式无效');
    }

    return json
        .map((item) => PluginCatalogItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<void> reload() async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(_fetch);
    if (!ref.mounted) return;
    state = nextState;
  }
}
