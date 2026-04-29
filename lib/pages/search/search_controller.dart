import 'dart:io';

import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/http/requests/request.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/models/item/image_search_item.dart';
import 'package:anime_flow/stores/search/search_history_manager.dart';
import 'package:get/get.dart';

class SearchPageController extends GetxController {
  /// 搜索结果
  final searchResults = Rxn<SubjectItem>();

  /// 图片搜索结果
  final imageSearchResults = RxList<ResultItem>();

  final isSearching = RxBool(false);
  final hasMore = RxBool(true);
  final currentKeyword = RxString('');
  final isImageSearching = RxBool(false);
  final imageSearchError = RxString('');

  static const int _limit = 10;
  int _offset = 0;

  Future<void> search(
      String query, {
        bool loadMore = false,
        Future<void> Function()? onHistoryChanged,
      }) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return;

    if (!loadMore) {
      await searchHistoryManager.saveSearchHistory(keyword);
      await onHistoryChanged?.call();
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
        keyword: currentKeyword.value,
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
