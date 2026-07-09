import 'dart:async';
import 'dart:io';

import 'package:anime_flow/network/requests/flow_request.dart';
import 'package:anime_flow/network/requests/request.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/models/item/image_search_item.dart';
import 'package:anime_flow/models/search/search_history_module.dart';
import 'package:anime_flow/repository/search/search_history_manager.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_controller.g.dart';

const _searchPageStateUnset = Object();

class SearchPageState {
  const SearchPageState({
    this.searchResults,
    this.searchSuggestions = const [],
    this.searchHistory = const [],
    this.imageSearchResults = const [],
    this.isSearching = false,
    this.hasMore = true,
    this.currentKeyword = '',
    this.isImageSearching = false,
    this.imageSearchError = '',
  });

  final SubjectItem? searchResults;
  final List<String> searchSuggestions;
  final List<SearchHistory> searchHistory;
  final List<ResultItem> imageSearchResults;
  final bool isSearching;
  final bool hasMore;
  final String currentKeyword;
  final bool isImageSearching;
  final String imageSearchError;

  SearchPageState copyWith({
    Object? searchResults = _searchPageStateUnset,
    List<String>? searchSuggestions,
    List<SearchHistory>? searchHistory,
    List<ResultItem>? imageSearchResults,
    bool? isSearching,
    bool? hasMore,
    String? currentKeyword,
    bool? isImageSearching,
    String? imageSearchError,
  }) {
    return SearchPageState(
      searchResults: identical(searchResults, _searchPageStateUnset)
          ? this.searchResults
          : searchResults as SubjectItem?,
      searchSuggestions: searchSuggestions ?? this.searchSuggestions,
      searchHistory: searchHistory ?? this.searchHistory,
      imageSearchResults: imageSearchResults ?? this.imageSearchResults,
      isSearching: isSearching ?? this.isSearching,
      hasMore: hasMore ?? this.hasMore,
      currentKeyword: currentKeyword ?? this.currentKeyword,
      isImageSearching: isImageSearching ?? this.isImageSearching,
      imageSearchError: imageSearchError ?? this.imageSearchError,
    );
  }
}

@Riverpod()
class SearchPageController extends _$SearchPageController {
  final SearchHistoryManager _searchHistoryManager = SearchHistoryManager();

  static const int _limit = 10;
  int _offset = 0;
  int _suggestionRequestId = 0;

  @override
  SearchPageState build() {
    final listenable = _searchHistoryManager.searchHistoryBox.listenable();
    listenable.addListener(_loadSearchHistory);
    ref.onDispose(() {
      listenable.removeListener(_loadSearchHistory);
    });
    return SearchPageState(
        searchHistory: _searchHistoryManager.getSearchHistory());
  }

  /// 搜索番剧
  Future<void> search(
    String query, {
    bool loadMore = false,
  }) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return;

    if (!loadMore) {
      clearSearchSuggestions();
      await _searchHistoryManager.saveHistory(keyword);
    }

    if (state.isSearching || (loadMore && !state.hasMore)) return;

    state = state.copyWith(isSearching: true);
    if (!loadMore) {
      state = state.copyWith(
        currentKeyword: keyword,
        searchResults: null,
        hasMore: true,
      );
      _offset = 0;
    }

    try {
      final offset = loadMore ? _offset : 0;
      final value = await FlowRequest.searchSubjectService(
        state.currentKeyword,
        limit: _limit,
        offset: offset,
      );

      final nextResults = loadMore && state.searchResults != null
          ? SubjectItem(
              data: [...state.searchResults!.data, ...value.data],
              total: value.total,
            )
          : value;

      _offset = offset + value.data.length;
      state = state.copyWith(
        searchResults: nextResults,
        hasMore: value.data.length == _limit &&
            nextResults.data.length < value.total,
      );
    } catch (_) {
    } finally {
      state = state.copyWith(isSearching: false);
    }
  }

  void _loadSearchHistory() {
    state = state.copyWith(
      searchHistory: _searchHistoryManager.getSearchHistory(),
    );
  }

  /// 搜索建议
  Future<void> fetchSearchSuggestions(String query) async {
    final keyword = query.trim();
    if (keyword.isEmpty) {
      clearSearchSuggestions();
      return;
    }

    final requestId = ++_suggestionRequestId;
    try {
      state = state.copyWith(searchSuggestions: const []);
      final suggestions =
          await FlowRequest.searchSuggestionsService(keyword, limit: 20);
      if (requestId != _suggestionRequestId) return;

      state = state.copyWith(
        searchSuggestions: suggestions.data
            .map((item) => item.displayName)
            .where((name) => name.isNotEmpty)
            .toList(growable: false),
      );
    } catch (_) {
      if (requestId != _suggestionRequestId) return;
      state = state.copyWith(searchSuggestions: const []);
    }
  }

  void clearSearchSuggestions() {
    _suggestionRequestId++;
    state = state.copyWith(searchSuggestions: const []);
  }

  Future<void> searchImageByFile(File imageFile) async {
    state = state.copyWith(
      isImageSearching: true,
      imageSearchError: '',
      imageSearchResults: const [],
    );
    try {
      final result = await Request.getAnimeInfoByImageFile(imageFile);
      final results = result.result ?? const <ResultItem>[];
      state = state.copyWith(imageSearchResults: results);
      if (result.error != null && result.error!.isNotEmpty) {
        state = state.copyWith(imageSearchError: result.error!);
      } else if (results.isEmpty) {
        state = state.copyWith(imageSearchError: '未找到匹配结果');
      }
    } catch (e) {
      state = state.copyWith(imageSearchError: '图片搜索失败，请稍后重试');
    } finally {
      state = state.copyWith(isImageSearching: false);
    }
  }

  Future<void> searchImageByUrl(String imageUrl) async {
    state = state.copyWith(
      isImageSearching: true,
      imageSearchError: '',
      imageSearchResults: const [],
    );
    try {
      final result = await Request.getAnimeInfoByImageUrl(imageUrl);
      final results = result.result ?? const <ResultItem>[];
      state = state.copyWith(imageSearchResults: results);
      if (result.error != null && result.error!.isNotEmpty) {
        state = state.copyWith(imageSearchError: result.error!);
      } else if (results.isEmpty) {
        state = state.copyWith(imageSearchError: '未找到匹配结果');
      }
    } catch (e) {
      state = state.copyWith(imageSearchError: '图片搜索失败，请检查图片地址或稍后重试');
    } finally {
      state = state.copyWith(isImageSearching: false);
    }
  }

  void clearImageSearchState() {
    state = state.copyWith(
      isImageSearching: false,
      imageSearchError: '',
      imageSearchResults: const [],
    );
  }

  void loadMore() {
    if (state.currentKeyword.isEmpty || state.isSearching || !state.hasMore) {
      return;
    }
    unawaited(search(state.currentKeyword, loadMore: true));
  }

  void clearResults() {
    state = state.copyWith(
      searchResults: null,
      currentKeyword: '',
      hasMore: true,
    );
    _offset = 0;
  }

  Future<void> clearAllHistory() async {
    await _searchHistoryManager.clearAllHistory();
    _loadSearchHistory();
  }

  Future<void> removeSearchHistory(String keyword) async {
    await _searchHistoryManager.removeSearchHistory(keyword);
    _loadSearchHistory();
  }
}
