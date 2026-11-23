import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef CollectionRevisionState = ({
  int revision,
  int episodeProgressRevision,
  Object? source,
});

/// Invalidates collection-dependent caches and detail views.
final collectionRevisionProvider =
    NotifierProvider<CollectionRevision, CollectionRevisionState>(
  CollectionRevision.new,
);

class CollectionRevision extends Notifier<CollectionRevisionState> {
  @override
  CollectionRevisionState build() =>
      (revision: 0, episodeProgressRevision: 0, source: null);

  void changed({Object? source, bool affectsEpisodeProgress = true}) {
    state = (
      revision: state.revision + 1,
      episodeProgressRevision:
          state.episodeProgressRevision + (affectsEpisodeProgress ? 1 : 0),
      source: source,
    );
  }
}

/// Sync results refresh lists/profile separately from detail-cache eviction.
/// Local optimistic edits only publish collectionRevisionProvider.
final collectionRefreshProvider =
    NotifierProvider<CollectionRefresh, int>(CollectionRefresh.new);

class CollectionRefresh extends Notifier<int> {
  @override
  int build() => 0;
  void changed() => state++;
}
