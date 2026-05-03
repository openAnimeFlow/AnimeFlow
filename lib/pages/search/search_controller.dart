import 'dart:io';

import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/http/requests/request.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/models/item/image_search_item.dart';
import 'package:anime_flow/models/search/search_history_module.dart';
import 'package:anime_flow/repository/search/search_history_manager.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/adapters.dart';

class SearchPageController extends GetxController {
  /// 搜索结果
  final searchResults = Rxn<SubjectItem>();

  /// 搜索建议结果
  final searchSuggestions = RxList<String>();

  /// 搜索历史
  final searchHistoryManager = SearchHistoryManager();

  /// 搜索历史列表
  final searchHistory = RxList<SearchHistory>();

  /// 图片搜索结果
  final imageSearchResults = RxList<ResultItem>();

  final isSearching = RxBool(false);
  final hasMore = RxBool(true);
  final currentKeyword = RxString('');
  final isImageSearching = RxBool(false);
  final imageSearchError = RxString('');

  static const int _limit = 10;
  int _offset = 0;
  int _suggestionRequestId = 0;

  @override
  void onInit() {
    super.onInit();
    /// 加载搜索历史
    _loadSearchHistory();
    searchHistoryManager.searchHistoryBox.listenable().addListener(_loadSearchHistory);
  }

  @override
  void onClose () {
    searchHistoryManager.searchHistoryBox.listenable().removeListener(_loadSearchHistory);
    super.onClose();
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
      await searchHistoryManager.saveHistory(keyword);
    }

    if (isSearching.value || (loadMore && !hasMore.value)) return;

    isSearching.value = true;
    if (!loadMore) {
      currentKeyword.value = keyword;
      _offset = 0;
      hasMore.value = true;
      searchResults.value = null;
    }

    try {
      final offset = loadMore ? _offset : 0;
      final value = await BgmRequest.searchSubjectService(
        currentKeyword.value,
        limit: _limit,
        offset: offset,
      );

      if (loadMore && searchResults.value != null) {
        final oldValue = searchResults.value!;
        searchResults.value = SubjectItem(
          data: [...oldValue.data, ...value.data],
          total: value.total,
        );
      } else {
        searchResults.value = value;
      }

      _offset = offset + value.data.length;
      hasMore.value = value.data.length == _limit &&
          searchResults.value!.data.length < value.total;
    } catch (_) {
    } finally {
      isSearching.value = false;
    }
  }

  void _loadSearchHistory() {
    searchHistory.clear();
    searchHistory.addAll(searchHistoryManager.getSearchHistory());
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
      searchSuggestions.clear();
      final searchRequest =
          await BgmRequest.searchSubjectService(keyword, limit: 20, offset: 0);
      if (requestId != _suggestionRequestId) return;

      searchSuggestions.addAll(searchRequest.data
          .map((item) => item.nameCN ?? item.name)
          .where((name) => name.isNotEmpty));
    } catch (_) {
      if (requestId != _suggestionRequestId) return;
      searchSuggestions.clear();
    }
  }

  void clearSearchSuggestions() {
    _suggestionRequestId++;
    searchSuggestions.clear();
  }

  Future<void> searchImageByFile(File imageFile) async {
    isImageSearching.value = true;
    imageSearchError.value = '';
    imageSearchResults.clear();
    try {
      final result = await Request.getAnimeInfoByImageFile(imageFile);
      imageSearchResults.value = result.result ?? [];
      if (result.error != null && result.error!.isNotEmpty) {
        imageSearchError.value = result.error!;
      } else if (imageSearchResults.isEmpty) {
        imageSearchError.value = '未找到匹配结果';
      }
    } catch (e) {
      imageSearchError.value = '图片搜索失败，请稍后重试';
    } finally {
      isImageSearching.value = false;
    }
  }

  Future<void> searchImageByUrl(String imageUrl) async {
    isImageSearching.value = true;
    imageSearchError.value = '';
    imageSearchResults.clear();
    try {
      final result = await Request.getAnimeInfoByImageUrl(imageUrl);
      imageSearchResults.addAll(result.result ?? []);
      if (result.error != null && result.error!.isNotEmpty) {
        imageSearchError.value = result.error!;
      } else if (imageSearchResults.isEmpty) {
        imageSearchError.value = '未找到匹配结果';
      }
    } catch (e) {
      imageSearchError.value = '图片搜索失败，请检查图片地址或稍后重试';
    } finally {
      isImageSearching.value = false;
    }
  }

  void clearImageSearchState() {
    isImageSearching.value = false;
    imageSearchError.value = '';
    imageSearchResults.clear();
  }

  void loadMore() {
    if (currentKeyword.value.isEmpty || isSearching.value || !hasMore.value) {
      return;
    }
    search(currentKeyword.value, loadMore: true);
  }

  void clearResults() {
    searchResults.value = null;
    currentKeyword.value = '';
    _offset = 0;
    hasMore.value = true;
  }
}
