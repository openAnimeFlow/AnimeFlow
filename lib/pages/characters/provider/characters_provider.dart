import 'package:anime_flow/network/api/flow_request.dart';
import 'package:anime_flow/models/item/bangumi/actor_item.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
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

  @override
  Future<CharactersViewState> build() async {
    final subjectId = ref.watch(charactersArgsProvider);
    final characters = await FlowRequest.charactersService(
      subjectId,
      limit: _pageSize,
      offset: 0,
    );
    return CharactersViewState(characters: characters);
  }

  void onScroll(ScrollMetrics metrics) {
    maybeAutoFillShortContent(metrics);

    if (metrics.maxScrollExtent <= 0) return;

    final nearBottom =
        metrics.pixels >= metrics.maxScrollExtent - _loadMoreThreshold;
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
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _loadMoreScheduled = false;
      await loadMore();
    });
  }

  void maybeAutoFillShortContent(ScrollMetrics metrics) {
    if (_autoFillScheduled) return;

    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    if (metrics.maxScrollExtent > _shortContentThreshold) return;

    _autoFillScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _autoFillScheduled = false;
      await loadMore();
    });
  }

  Future<void> loadMore() async {
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

    try {
      final prev = current.characters;
      final subjectId = ref.read(charactersArgsProvider);
      final result = await FlowRequest.charactersService(
        subjectId,
        limit: _pageSize,
        offset: prev.data.length,
      );
      final merged = CharactersItem(
        data: [...prev.data, ...result.data],
        total: result.total,
      );
      state = AsyncData(CharactersViewState(characters: merged));
    } catch (_) {
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
