import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryManager {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryCount = 20;

  /// 保存搜索记录
  Future<void> saveSearchHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();

    // 移除重复项
    history.removeWhere((item) => item == keyword);
    // 添加到开头
    history.insert(0, keyword);

    //限制历史记录数量
    if (history.length > _maxHistoryCount) {
      history.removeRange(_maxHistoryCount, history.length);
    }
    await prefs.setString(_searchHistoryKey, jsonEncode(history));
  }

  /// 获取搜索历史
  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_searchHistoryKey);

    if (historyString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(historyString);
      return decoded.cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// 清除搜索历史
  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }

  /// 删除单个搜索记录
  Future<void> removeSearchHistoryItem(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();

    history.removeWhere((item) => item == keyword);
    await prefs.setString(_searchHistoryKey, jsonEncode(history));
  }
}

final searchHistoryManager = SearchHistoryManager();
