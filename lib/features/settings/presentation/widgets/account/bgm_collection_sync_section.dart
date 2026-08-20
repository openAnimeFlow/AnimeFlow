import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
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
        final message = item?.message;
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
