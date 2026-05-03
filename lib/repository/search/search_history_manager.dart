import 'package:anime_flow/models/search/search_history_module.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:logger/logger.dart';

class SearchHistoryManager {
  static const int _maxHistoryCount = 20;

  final searchHistoryBox = Storage.searchHistory;

  /// 保存搜索记录
  Future<bool> saveHistory(String keyword) async {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty) return false;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final history = SearchHistory(trimmedKeyword, timestamp);
      await searchHistoryBox.put(trimmedKeyword, history);
      await _trimHistory();
      return true;
    } catch (e, stackTrace) {
      Logger().e(
        'GStorage: save search history failed. keyword=$keyword',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 获取搜索历史
  List<SearchHistory> getSearchHistory() {
    try {
      final histories = searchHistoryBox.values.toList().cast<SearchHistory>();
      histories.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return histories;
    } catch (e, stackTrace) {
      Logger().e(
        'GStorage: get search history failed.',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// 清除搜索历史
  Future<void> clearAllHistory() async {
    try {
      await searchHistoryBox.clear();
    } catch (e, stackTrace) {
      Logger().e(
        'GStorage: clear all search histories failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 删除单个搜索记录
  Future<void> removeSearchHistory(String keyword) async {
    try {
      await searchHistoryBox.delete(keyword.trim());
    } catch (e, stackTrace) {
      Logger().e(
        'GStorage: delete search history failed. key=${keyword.trim()}',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  List<MapEntry<dynamic, SearchHistory>> _sortedHistoryEntries() {
    final entries = searchHistoryBox.toMap().entries.toList();
    entries.sort(
      (a, b) => b.value.timestamp.compareTo(a.value.timestamp),
    );
    return entries;
  }


  Future<void> _trimHistory() async {
    final entries = _sortedHistoryEntries();
    if (entries.length <= _maxHistoryCount) return;

    final keys =
        entries.skip(_maxHistoryCount).map((entry) => entry.key).toList();
    await searchHistoryBox.deleteAll(keys);
  }
}