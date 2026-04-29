import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/stores/search/search_history_manager.dart';
import 'package:get/get.dart';

class SearchController extends GetxController {
  final searchResults = Rxn<SubjectItem>();
  final isSearching = RxBool(false);
  final hasMore = RxBool(true);
  final currentKeyword = RxString('');

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
