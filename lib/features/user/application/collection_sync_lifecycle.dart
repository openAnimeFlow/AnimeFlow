import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bgm_collection_sync_provider.dart';

/// Keeps discovery independent of the account settings page. Never starts a sync.
class CollectionSyncLifecycle extends ConsumerStatefulWidget {
  const CollectionSyncLifecycle({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<CollectionSyncLifecycle> createState() =>
      _CollectionSyncLifecycleState();
}

class _CollectionSyncLifecycleState
    extends ConsumerState<CollectionSyncLifecycle> {
  late final AppLifecycleListener _lifecycle;
  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () =>
          ref.read(bgmCollectionSyncProvider.notifier).setForeground(false),
      onPause: () =>
          ref.read(bgmCollectionSyncProvider.notifier).setForeground(false),
      onResume: () async {
        if (ref.read(bgmCollectionSyncProvider).hasError) {
          ref.invalidate(bangumiBindProvider);
          ref.invalidate(bgmCollectionSyncProvider);
          return;
        }
        final notifier = ref.read(bgmCollectionSyncProvider.notifier);
        notifier.setForeground(true);
        try {
          await notifier.refreshStatus();
        } catch (_) {}
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(bgmCollectionSyncProvider);
    return widget.child;
  }
}
