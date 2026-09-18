import 'package:anime_flow/core/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/features/source/application/providers/source_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'source_configs_provider.g.dart';

@riverpod
class SourceConfigs extends _$SourceConfigs {
  @override
  Future<List<CrawlConfigItem>> build() async {
    final repository = ref.watch(sourceRepositoryProvider);

    void onChanged() {
      ref.invalidateSelf();
    }

    repository.listenable.addListener(onChanged);
    ref.onDispose(() => repository.listenable.removeListener(onChanged));

    return repository.getSources();
  }
}
