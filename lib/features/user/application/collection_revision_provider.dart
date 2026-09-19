import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Watched by scoped subject pages as well as global collection caches.
final collectionRevisionProvider =
    NotifierProvider<CollectionRevision, int>(CollectionRevision.new);

class CollectionRevision extends Notifier<int> {
  @override
  int build() => 0;
  void changed() => state++;
}
