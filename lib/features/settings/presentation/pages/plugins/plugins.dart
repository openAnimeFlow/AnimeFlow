import 'dart:math' as math;

import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/features/source/application/providers/plugin_provider.dart';
import 'package:anime_flow/features/source/application/providers/source_configs_provider.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/features/source/data/repositories/source_repository.dart';
import 'package:anime_flow/features/settings/presentation/pages/plugins/plugin_install_message.dart';
import 'package:anime_flow/features/source/application/providers/source_repository_provider.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

class PluginsPage extends ConsumerStatefulWidget {
  const PluginsPage({super.key});

  @override
  ConsumerState<PluginsPage> createState() => _PluginsPageState();
}

class _PluginsPageState extends ConsumerState<PluginsPage> {
  late final SourceRepository _sourceRepository;
  final Set<String> _busyPluginNames = {};

  /// 串行化排序写入。
  Future<void> _orderWriteChain = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _sourceRepository = ref.read(sourceRepositoryProvider);
  }

  Future<void> deleteDataSource(String name) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.deleteSourceConfirmation(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _sourceRepository.deleteSource(name);
      if (!mounted) return;
      NotificationToast.show(l10n.sourceDeleted(name),
          title: l10n.deleteSuccess);
    } catch (e) {
      NotificationToast.show(
        l10n.sourceDeleteFailed(name, e.toString()),
        title: l10n.deleteFailed,
      );
    }
  }

  Future<void> _updatePlugin(PluginCatalogItem plugin) async {
    if (_busyPluginNames.contains(plugin.name)) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busyPluginNames.add(plugin.name);
    });
    try {
      await _sourceRepository.updatePlugin(
        pluginPath: plugin.path,
        catalogVersion: plugin.version,
      );
      if (!mounted) return;
      NotificationToast.show(
        l10n.pluginUpdated(plugin.name, plugin.version),
        title: l10n.updateSuccess,
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      LiggLogger().e(
        'Plugins: 更新规则 ${plugin.name} 失败',
        error: error,
        stackTrace: stackTrace,
      );
      NotificationToast.show(
        pluginInstallErrorMessage(
          l10n,
          plugin.name,
          error,
          isUpdate: true,
        ),
        title: l10n.updateFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyPluginNames.remove(plugin.name);
        });
      }
    }
  }

  Future<void> _copyPlugin(String name) async {
    final l10n = AppLocalizations.of(context);
    try {
      final content = await _sourceRepository.exportPlugin(name);
      await Clipboard.setData(ClipboardData(text: content));
      if (!mounted) return;
      NotificationToast.show(
        l10n.pluginCopied(name),
        title: l10n.copyPlugin,
      );
    } catch (error) {
      if (!mounted) return;
      NotificationToast.show(
        l10n.pluginCopyFailed(name, error.toString()),
        title: l10n.copyPlugin,
      );
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    // 先同步更新列表顺序，松手后列表才会立即停在新位置；写入失败时再回滚。
    ref.read(sourceConfigsProvider.notifier).reorder(oldIndex, newIndex);
    _orderWriteChain =
        _orderWriteChain.then((_) => _saveReorder(oldIndex, newIndex));
  }

  Future<void> _saveReorder(int oldIndex, int newIndex) async {
    try {
      await _sourceRepository.reorderSources(oldIndex, newIndex);
    } catch (error, stackTrace) {
      if (!mounted) return;
      LiggLogger().e(
        'Plugins: 数据源排序保存失败',
        error: error,
        stackTrace: stackTrace,
      );
      ref.invalidate(sourceConfigsProvider);
      final l10n = AppLocalizations.of(context);
      NotificationToast.show(
        l10n.dataSaveFailed(error.toString()),
        title: l10n.saveFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paddingOf = MediaQuery.paddingOf(context);
    final sourceConfigs = ref.watch(sourceConfigsProvider);
    final remotePlugins = ref.watch(pluginCatalogProvider).whenOrNull(
              data: (plugins) => plugins,
            ) ??
        const <PluginCatalogItem>[];
    final remotePluginsByName = {
      for (final plugin in remotePlugins) plugin.name: plugin,
    };
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer(
          builder: (context, ref, _) {
            final isWideScreen = ref.watch(settingsLayoutProvider);
            return AppBar(
              title: Text(l10n.sourceManagement),
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
      body: sourceConfigs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (dataSources) => LayoutBuilder(
          builder: (context, constraints) {
            final horizontal =
                math.max(10.0, (constraints.maxWidth - 1500.0) / 2);
            return ReorderableListView.builder(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                0,
                horizontal,
                paddingOf.bottom,
              ),
              itemCount: dataSources.length,
              buildDefaultDragHandles: false,
              onReorderItem: _onReorder,
              itemBuilder: (context, index) {
                final data = dataSources[index];
                final remotePlugin = remotePluginsByName[data.name];
                final hasUpdate = remotePlugin != null &&
                    Utils.compareVersionNumbers(
                            remotePlugin.version, data.version) >
                        0;
                final isPluginBusy = _busyPluginNames.contains(data.name);
                return InkWell(
                  key: ValueKey(data.name),
                  onTap: () => SettingAddPluginsRoute(editPluginKey: data.name)
                      .push(context),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context)
                            .disabledColor
                            .withValues(alpha: 0.1)),
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: [
                                    Text(data.version),
                                    if (hasUpdate) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.updateAvailable,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              ]),
                        ),
                        if (hasUpdate)
                          TextButton(
                            onPressed: isPluginBusy
                                ? null
                                : () => _updatePlugin(remotePlugin),
                            child: isPluginBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(l10n.update),
                          ),
                        IconButton(
                          tooltip: l10n.copyPlugin,
                          icon: const Icon(Icons.content_copy_outlined),
                          onPressed: () => _copyPlugin(data.name),
                        ),
                        IconButton(
                          tooltip: l10n.delete,
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => deleteDataSource(data.name),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
