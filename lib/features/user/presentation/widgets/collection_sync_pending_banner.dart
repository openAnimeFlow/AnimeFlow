import 'package:anime_flow/shared/models/flow/bgm_collection_sync_status_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/features/user/application/bgm_collection_sync_provider.dart';

class CollectionSyncPendingBanner extends ConsumerWidget {
  const CollectionSyncPendingBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bgmCollectionSyncProvider);
    final status = async.isLoading ? null : async.value;
    if (status == null ||
        (status.pendingConflictCount == 0 &&
            status.failedCount == 0 &&
            status.status != BgmCollectionSyncStatus.partialFailed)) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.sync_problem_outlined),
        title: Text(status.pendingConflictCount == 0 && status.failedCount == 0
            ? AppLocalizations.of(context).syncPartialFailed
            : AppLocalizations.of(context).syncPendingSummary(
                status.pendingConflictCount, status.failedCount)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => const SettingAccountRoute().push(context),
      ),
    );
  }
}
