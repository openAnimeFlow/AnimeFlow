import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/features/source/application/providers/source_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'source_configs_provider.g.dart';

@riverpod
class SourceConfigs extends _$SourceConfigs {
  @override
  Future<List<CrawlConfigItem>> build() async {
    final repository = ref.watch(sourceRepositoryProvider);

    final listenable = repository.listenable;

    void onChanged() {
      if (!ref.mounted) return;
      Future<void>.microtask(() {
        if (!ref.mounted) return;
        ref.invalidateSelf();
      });
    }

    listenable.addListener(onChanged);
    ref.onDispose(() => listenable.removeListener(onChanged));

    return repository.getSources();
  }

  void reorder(int oldIndex, int newIndex) {
    final current = state.value;
    if (current == null) return;
    if (oldIndex < 0 || oldIndex >= current.length) return;
    if (newIndex < 0 || newIndex >= current.length) return;
    if (oldIndex == newIndex) return;

    final reordered = [...current];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    state = AsyncData(reordered);
  }
}
