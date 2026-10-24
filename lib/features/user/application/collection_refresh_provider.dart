import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sync results refresh lists/profile separately from detail-cache eviction.
/// Local optimistic edits only publish collectionRevisionProvider.
final collectionRefreshProvider =
    NotifierProvider<CollectionRefresh, int>(CollectionRefresh.new);

class CollectionRefresh extends Notifier<int> {
  @override
  int build() => 0;
  void changed() => state++;
}
