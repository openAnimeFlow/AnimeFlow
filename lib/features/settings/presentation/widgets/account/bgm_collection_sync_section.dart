import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/flow/bgm_collection_sync_status_item.dart';
import 'package:anime_flow/features/user/application/bgm_collection_sync_provider.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bangumi 收藏同步设置区块。
class BangumiCollectionSyncSection extends ConsumerStatefulWidget {
  const BangumiCollectionSyncSection({super.key});

  @override
  ConsumerState<BangumiCollectionSyncSection> createState() =>
      _BangumiCollectionSyncSectionState();
}

class _BangumiCollectionSyncSectionState
    extends ConsumerState<BangumiCollectionSyncSection> {
  bool _isSubmitting = false;

  Future<void> _triggerSync() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(bgmCollectionSyncProvider.notifier).triggerSync();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      NotificationToast.show(l10n.collectionSyncStarted, title: l10n.tip);
    } catch (e) {
      if (!mounted) return;
      final message = e is AnimeFlowApiException
          ? e.message
          : e is StateError
              ? e.message
              : AppLocalizations.of(context).syncStartFailed;
      NotificationToast.show(message, title: AppLocalizations.of(context).tip);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _refreshStatus() async {
    try {
      await ref.read(bgmCollectionSyncProvider.notifier).refreshStatus();
    } catch (e) {
      if (!mounted) return;
      final message = e is AnimeFlowApiException
          ? e.message
          : AppLocalizations.of(context).refreshStatusFailed;
      NotificationToast.show(message, title: AppLocalizations.of(context).tip);
    }
  }

  Future<void> _resolveConflicts(int taskId) async {
    try {
      final conflicts =
          await FlowApi.getCollectionConflictsService(taskId: taskId);
      if (!mounted || conflicts.isEmpty) return;
      final selected = <int, int>{};
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('处理收藏分类冲突'),
            content: SizedBox(
              width: 520,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: conflicts.length,
                itemBuilder: (_, index) {
                  final item = conflicts[index];
                  return ListTile(
                    title: Text(item.subjectName ?? '条目 ${item.subjectId}'),
                    subtitle: Text(
                        '本地：${_typeName(item.localType)}  Bangumi：${_typeName(item.remoteType)}'),
                    trailing: DropdownButton<int>(
                      value: selected[item.conflictId],
                      hint: const Text('选择'),
                      items: List.generate(
                          5,
                          (i) => DropdownMenuItem(
                              value: i + 1, child: Text(_typeName(i + 1)))),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(
                              () => selected[item.conflictId] = value);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('稍后处理')),
              FilledButton(
                onPressed: selected.length == conflicts.length
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                child: const Text('提交选择'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      final byId = {for (final item in conflicts) item.conflictId: item};
      await FlowApi.resolveCollectionConflictsService(
        taskId: taskId,
        items: selected.entries.map((entry) {
          final item = byId[entry.key]!;
          return {
            'conflictId': item.conflictId,
            'conflictVersion': item.conflictVersion,
            'selectedType': entry.value
          };
        }).toList(),
      );
      await _refreshStatus();
    } catch (error) {
      if (mounted) NotificationToast.show(error.toString(), title: '冲突处理失败');
    }
  }

  String _typeName(int? type) => switch (type) {
        1 => '想看',
        2 => '看过',
        3 => '在看',
        4 => '搁置',
        5 => '抛弃',
        _ => '未知',
      };

  @override
  Widget build(BuildContext context) {
    final syncAsync = ref.watch(bgmCollectionSyncProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return syncAsync.when(
      data: (status) {
        final item = status;
        final isRunning = item?.isRunning == true || _isSubmitting;
        final statusLabel = _statusLabel(l10n, item?.status);
        final message = switch (item?.message) {
          'SYNC_RETRY_REQUIRED' ||
          'ITEM_RETRY_REQUIRED' =>
            '同步暂时失败，服务端会自动重试。恢复后将继续检查收藏冲突。',
          'SYNC_BINDING_CHANGED' => 'Bangumi 绑定已变更，请重新发起同步。',
          _ => item?.message,
        };
        final syncedCount = item?.syncedCount ?? 0;
        final totalCount = item?.totalCount ?? 0;
        final hasProgress = isRunning && totalCount > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sync_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.collectionSyncTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: l10n.refreshStatus,
                  onPressed: isRunning ? null : _refreshStatus,
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SyncStatusChip(
                  label: statusLabel,
                  status: item?.status ?? BgmCollectionSyncStatus.idle,
                ),
                if (isRunning) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            if (message != null && message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if ((item?.pendingConflictCount ?? 0) > 0 &&
                item?.taskId != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: Text('有 ${item!.pendingConflictCount} 条收藏分类冲突待处理')),
                OutlinedButton(
                    onPressed: () => _resolveConflicts(item.taskId!),
                    child: const Text('处理冲突')),
              ]),
            ],
            if (hasProgress) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: syncedCount / totalCount,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 4),
              Text(
                '$syncedCount / $totalCount',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (isRunning && syncedCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                l10n.syncedItems(syncedCount),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isRunning ? null : _triggerSync,
                icon: const Icon(Icons.cloud_download_outlined, size: 18),
                label: Text(isRunning
                    ? l10n.syncInProgress
                    : l10n.syncBangumiCollection),
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.collectionSyncTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.syncStatusLoadFailed,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(bgmCollectionSyncProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  String _statusLabel(
    AppLocalizations l10n,
    BgmCollectionSyncStatus? status,
  ) {
    switch (status ?? BgmCollectionSyncStatus.idle) {
      case BgmCollectionSyncStatus.idle:
        return l10n.syncStatusIdle;
      case BgmCollectionSyncStatus.queued:
        return '排队中';
      case BgmCollectionSyncStatus.waitingConflict:
        return '等待处理冲突';
      case BgmCollectionSyncStatus.partialFailed:
        return '部分失败';
      case BgmCollectionSyncStatus.cancelled:
        return '已取消';
      case BgmCollectionSyncStatus.running:
        return l10n.syncStatusRunning;
      case BgmCollectionSyncStatus.success:
        return l10n.syncStatusSuccess;
      case BgmCollectionSyncStatus.failed:
        return l10n.syncStatusFailed;
    }
  }
}

/// 同步状态标签 Chip。
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({
    super.key,
    required this.label,
    required this.status,
  });

  final String label;
  final BgmCollectionSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (status) {
      BgmCollectionSyncStatus.running => (
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
        ),
      BgmCollectionSyncStatus.queued ||
      BgmCollectionSyncStatus.waitingConflict ||
      BgmCollectionSyncStatus.partialFailed =>
        (
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
        ),
      BgmCollectionSyncStatus.success => (
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
        ),
      BgmCollectionSyncStatus.failed => (
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
        ),
      BgmCollectionSyncStatus.idle => (
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
        ),
      BgmCollectionSyncStatus.cancelled => (
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}
