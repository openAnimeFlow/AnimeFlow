import 'dart:convert';

import 'package:anime_flow/core/network/clients/rules_repo_client.dart';
import 'package:anime_flow/core/crawler/rule_api_level.dart';
import 'package:anime_flow/core/network/api_path.dart';
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

@riverpod
class PluginCatalog extends _$PluginCatalog {
  CancelToken? _cancelToken;

  @override
  Future<List<PluginCatalogItem>> build() {
    ref.onDispose(() {
      _cancelActiveRequest('插件目录 Provider 已销毁');
    });
    return _fetch();
  }

  void _cancelActiveRequest(String reason) {
    final cancelToken = _cancelToken;
    if (cancelToken == null || cancelToken.isCancelled) return;
    cancelToken.cancel(reason);
  }

  Future<List<PluginCatalogItem>> _fetch() async {
    _cancelActiveRequest('插件目录请求已被新的请求替换');
    final cancelToken = _cancelToken = CancelToken();
    final data = await RulesRepoClient.instance.getText(
        '${CommonApi.pluginRepo}/index.json',
        cancelToken: cancelToken);
    final json = jsonDecode(data);
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
    // Let Riverpod cancel the previous build subscription as well as the HTTP
    // request, so an old response cannot overwrite the newly selected route.
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The provider's AsyncError is rendered by the catalog page.
    }
  }
}
