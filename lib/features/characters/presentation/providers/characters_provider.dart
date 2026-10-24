import 'package:anime_flow/features/characters/data/repositories/character_repository.dart';
import 'package:dio/dio.dart';
import 'package:anime_flow/shared/models/bangumi/actor_item.dart';
import 'package:anime_flow/features/characters/presentation/providers/characters_args_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'characters_provider.g.dart';

class CharactersViewState {
  const CharactersViewState({
    required this.characters,
    this.isLoadingMore = false,
  });

  final CharactersItem characters;
  final bool isLoadingMore;

  bool get hasMore => characters.data.length < characters.total;
}

@Riverpod(dependencies: [charactersArgs])
class CharactersList extends _$CharactersList {
  static const _pageSize = 10;
  static const _loadMoreThreshold = 200.0;
  static const _shortContentThreshold = 50.0;

  bool _armedForBottomLoad = true;
  bool _loadMoreScheduled = false;
  bool _autoFillScheduled = false;
  late CancelToken _cancelToken;
  bool _forceRefresh = false;

  @override
  Future<CharactersViewState> build() async {
    final subjectId = ref.watch(charactersArgsProvider);
    final token = _cancelToken = CancelToken();
    ref.onDispose(() => token.cancel());
    _armedForBottomLoad = true;
    _loadMoreScheduled = false;
    _autoFillScheduled = false;
    _forceRefresh = !ref.isFirstBuild;
    final characters =
        await ref.watch(characterRepositoryProvider.notifier).getCharacters(
              subjectId,
              limit: _pageSize,
              offset: 0,
              cancelToken: token,
              forceRefresh: _forceRefresh,
            );
    return CharactersViewState(characters: characters);
  }

  void onScroll({required double pixels, required double maxScrollExtent}) {
    maybeAutoFillShortContent(maxScrollExtent);

    if (maxScrollExtent <= 0) return;

    final nearBottom = pixels >= maxScrollExtent - _loadMoreThreshold;
    if (!nearBottom) {
      _armedForBottomLoad = true;
      return;
    }
    if (!_armedForBottomLoad || _loadMoreScheduled) return;

    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    _armedForBottomLoad = false;
    _loadMoreScheduled = true;
    // 当前同步通知结束后再请求，合并同一轮的重复分页信号。
    Future<void>.microtask(() async {
      _loadMoreScheduled = false;
      await loadMore();
    });
  }

  void maybeAutoFillShortContent(double maxScrollExtent) {
    if (_autoFillScheduled) return;

    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    if (maxScrollExtent > _shortContentThreshold) return;

    _autoFillScheduled = true;
    // 当前同步通知结束后再请求，合并同一轮的重复分页信号。
    Future<void>.microtask(() async {
      _autoFillScheduled = false;
      await loadMore();
    });
  }

  Future<void> loadMore() async {
    if (!ref.mounted) return;
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(
      CharactersViewState(
        characters: current.characters,
        isLoadingMore: true,
      ),
    );

    final token = _cancelToken;
    try {
      final prev = current.characters;
      final subjectId = ref.read(charactersArgsProvider);
      final result =
          await ref.read(characterRepositoryProvider.notifier).getCharacters(
                subjectId,
                limit: _pageSize,
                offset: prev.data.length,
                cancelToken: token,
                forceRefresh: _forceRefresh,
              );
      if (!ref.mounted || token.isCancelled) return;
      final merged = CharactersItem(
        data: [...prev.data, ...result.data],
        total: result.total,
      );
      state = AsyncData(CharactersViewState(characters: merged));
    } catch (_) {
      if (!ref.mounted || token.isCancelled) return;
      _armedForBottomLoad = true;
      state = AsyncData(
        CharactersViewState(
          characters: current.characters,
          isLoadingMore: false,
        ),
      );
    }
  }
}
